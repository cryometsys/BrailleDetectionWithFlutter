import os
import json
import uuid
from datetime import datetime
from typing import Dict, List, Optional
import firebase_admin
from firebase_admin import credentials, firestore, storage
from detector import BrailleDetector
from assistant import BrailleAssistant
import base64
from PIL import Image
import io

class BrailleFirebaseService:
    def __init__(self, firebase_config_path: str = None):
        """Initialize Firebase service"""
        
        # Initialize Firebase if not already done
        if not firebase_admin._apps:
            if firebase_config_path and os.path.exists(firebase_config_path):
                cred = credentials.Certificate(firebase_config_path)
                firebase_admin.initialize_app(cred, {
                    'storageBucket': 'your-project-id.appspot.com'  # Replace with your bucket
                })
            else:
                # For development - use default credentials
                firebase_admin.initialize_app()
        
        self.db = firestore.client()
        self.storage_client = storage.bucket()
        
        # Initialize detection components
        self.detector = BrailleDetector()
        self.assistant = BrailleAssistant()
    
    def upload_image_to_storage(self, image_data: bytes, filename: str) -> str:
        """Upload image to Firebase Storage and return download URL"""
        try:
            # Create unique filename
            unique_filename = f"braille_images/{uuid.uuid4()}_{filename}"
            
            # Upload to Firebase Storage
            blob = self.storage_client.blob(unique_filename)
            blob.upload_from_string(image_data, content_type='image/jpeg')
            
            # Make it publicly accessible
            blob.make_public()
            
            return blob.public_url
        except Exception as e:
            print(f"Error uploading image: {e}")
            return None
    
    def save_detection_result(self, session_id: str, result_data: Dict) -> str:
        """Save detection result to Firestore"""
        try:
            doc_ref = self.db.collection('braille_detections').document()
            
            detection_doc = {
                'session_id': session_id,
                'timestamp': datetime.utcnow(),
                'image_url': result_data.get('image_url', ''),
                'annotated_image_url': result_data.get('annotated_image_url', ''),
                'detected_text_rows': result_data.get('detected_text_rows', []),
                'processed_text': result_data.get('processed_text', ''),
                'explanation': result_data.get('explanation', ''),
                'confidence': result_data.get('confidence', 0.0),
                'raw_predictions': result_data.get('raw_predictions', []),
                'status': 'completed'
            }
            
            doc_ref.set(detection_doc)
            return doc_ref.id
        except Exception as e:
            print(f"Error saving to Firestore: {e}")
            return None
    
    def get_session_results(self, session_id: str) -> List[Dict]:
        """Get all detection results for a session"""
        try:
            docs = self.db.collection('braille_detections')\
                         .where('session_id', '==', session_id)\
                         .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                         .stream()
            
            results = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                # Convert timestamp to string for JSON serialization
                if 'timestamp' in data:
                    data['timestamp'] = data['timestamp'].isoformat()
                results.append(data)
            
            return results
        except Exception as e:
            print(f"Error getting session results: {e}")
            return []
    
    def process_braille_image(self, image_data: bytes, filename: str, session_id: str = None) -> Dict:
        """Full pipeline: detect, process, and save braille image"""
        
        if not session_id:
            session_id = str(uuid.uuid4())
        
        try:
            # Save original image temporarily
            temp_image_path = f"temp_{uuid.uuid4()}.jpg"
            with open(temp_image_path, 'wb') as f:
                f.write(image_data)
            
            print(f"Processing image: {filename}")
            
            # Step 1: Upload original image to Firebase Storage
            original_image_url = self.upload_image_to_storage(image_data, filename)
            
            # Step 2: Run braille detection
            detection_result = self.detector.detect_braille(temp_image_path)
            
            if not detection_result:
                return {
                    'success': False,
                    'error': 'Detection failed',
                    'session_id': session_id
                }
            
            # Step 3: Extract predictions
            predictions = self.detector.extract_predictions(detection_result)
            print(f"Detected {len(predictions)} braille characters")
            
            # Step 4: Create annotated image
            annotated_path = f"temp_annotated_{uuid.uuid4()}.png"
            annotation_success = self.detector.create_annotated_image(
                temp_image_path, 
                predictions, 
                annotated_path
            )
            
            annotated_image_url = None
            if annotation_success:
                # Upload annotated image
                with open(annotated_path, 'rb') as f:
                    annotated_data = f.read()
                annotated_image_url = self.upload_image_to_storage(
                    annotated_data, 
                    f"annotated_{filename}"
                )
                os.remove(annotated_path)
            
            # Step 5: Organize text into rows
            text_rows = self.detector.organize_text_by_rows(predictions)
            
            # Step 6: Process with AI assistant
            braille_result = self.assistant.process_braille_strings(text_rows)
            
            # Step 7: Prepare result data
            result_data = {
                'image_url': original_image_url,
                'annotated_image_url': annotated_image_url,
                'detected_text_rows': text_rows,
                'processed_text': braille_result.text,
                'explanation': braille_result.explanation,
                'confidence': braille_result.confidence,
                'raw_predictions': predictions[:10]  # Limit for storage
            }
            
            # Step 8: Save to Firestore
            doc_id = self.save_detection_result(session_id, result_data)
            
            # Cleanup
            os.remove(temp_image_path)
            
            return {
                'success': True,
                'session_id': session_id,
                'document_id': doc_id,
                'result': {
                    'original_image': original_image_url,
                    'annotated_image': annotated_image_url,
                    'detected_rows': text_rows,
                    'processed_text': braille_result.text,
                    'explanation': braille_result.explanation,
                    'confidence': braille_result.confidence,
                    'character_count': len(predictions)
                }
            }
            
        except Exception as e:
            print(f"Error in processing pipeline: {e}")
            return {
                'success': False,
                'error': str(e),
                'session_id': session_id
            }
    
    def create_session(self) -> str:
        """Create a new session"""
        session_id = str(uuid.uuid4())
        
        try:
            # Create session document
            session_doc = {
                'session_id': session_id,
                'created_at': datetime.utcnow(),
                'status': 'active'
            }
            
            self.db.collection('braille_sessions').document(session_id).set(session_doc)
            return session_id
        except Exception as e:
            print(f"Error creating session: {e}")
            return session_id  # Return anyway for basic functionality


# Flask API wrapper for the service
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Initialize service
firebase_service = BrailleFirebaseService()

@app.route('/api/process-braille', methods=['POST'])
def process_braille():
    """API endpoint to process braille image"""
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        session_id = request.form.get('session_id')
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Read image data
        image_data = file.read()
        
        # Process the image
        result = firebase_service.process_braille_image(
            image_data, 
            file.filename, 
            session_id
        )
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/session/<session_id>/results', methods=['GET'])
def get_session_results(session_id):
    """Get all results for a session"""
    try:
        results = firebase_service.get_session_results(session_id)
        return jsonify({'results': results})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/create-session', methods=['POST'])
def create_session():
    """Create a new session"""
    try:
        session_id = firebase_service.create_session()
        return jsonify({'session_id': session_id})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("Starting Braille Firebase Service API...")
    print("Endpoints:")
    print("- POST /api/process-braille")
    print("- GET /api/session/<session_id>/results")
    print("- POST /api/create-session")
    app.run(debug=True, host='0.0.0.0', port=5000)