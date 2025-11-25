import time
from appwrite.client import Client
from dotenv import load_dotenv
from appwrite.exception import AppwriteException
from appwrite.services.databases import Databases
import os
import json

load_dotenv('appwrite/.env')

# Helper: load JSON from training_data
def load_json(path):
    if not os.path.exists(path):
        print(f"Warning: {path} not found, returning empty list")
        return []
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

# http://localhost/v1
endpoint = os.getenv('APPWRITE_URL')
project_id = os.getenv('APPWRITE_PROJECT_ID')
api_key = os.getenv('APPWRITE_API_KEY')
db_id = os.getenv('APPWRITE_DATABASE_ID')

client = Client()

(client
    .set_endpoint(endpoint)
    .set_project(project_id)
    .set_key(api_key)
    # .set_self_signed() # Use only on dev mode with a self-signed SSL cert
    )

# Appwrite does not support unique indexes on relationship types as of late 2025 so we have to use a stringtype for identifiers
# To enforce uniqueness we store IDs as strings and build composite unique indexes on them.
collections_config = load_json('appwrite_collections_config.json')

sample_topics = load_json('training_data/sample_topics.json')
sample_posts = load_json('training_data/sample_posts.json')
sample_events = load_json('training_data/sample_events.json')
sample_comments = load_json('training_data/sample_comments.json')
sample_announcements = load_json('training_data/sample_announcements.json')
sample_surveys = load_json('training_data/sample_surveys.json')
sample_event_likes = load_json('training_data/likes/sample_event_likes.json')
sample_post_likes = load_json('training_data/likes/sample_post_likes.json')
sample_comment_likes = load_json('training_data/likes/sample_comment_likes.json')


def seed_collection(file_path, collection):
    data = load_json(file_path)
    for doc in data:
        doc_id = doc.pop("id", "unique()")  # Remove 'id' from doc data
        try:
            databases.create_document(db_id, collection, doc_id, doc)
            print(f"[SUCCESS] {collection}/{doc_id}")
        except AppwriteException as e:
            print(f"[SKIPPED] {collection}/{doc_id}: {e.message}")


def create_unique_like_index(collection_id, index_name, fields):
    try:
        print(f"Creating unique index {index_name} on {collection_id}...")
        databases.create_index(db_id, collection_id, index_name, "unique", fields, ['ASC', 'ASC'] )
        print(f"  [SUCCESS] Created {index_name}")
    except AppwriteException as e:
        # Most common case: index already exists → skip without failing the run
        print(f"  [SKIPPED] {index_name}: Index already exists")

def create_like_indexes():
    create_unique_like_index("event_likes", "eventId_userId_unique", ["eventId", "userId"])
    create_unique_like_index("post_likes",  "postId_userId_unique",  ["postId", "userId"])
    create_unique_like_index("comment_likes","commentId_userId_unique",["commentId", "userId"])

    
def create_database(databases: Databases):
    print('Creating database', db_id)
    try:
        databases.get(db_id)
        print(f"Database {db_id} already exists")
    except AppwriteException as e:
        # Database does not exist, create it
        result = databases.create(db_id, 'Community app database')
        print(result)
    
def create_collections(databases: Databases):
    for collection in collections_config:
        cid = collection['collection_id']
        name = collection['name']
        print(f"Creating collection: {name}")

        # Check if collection exists
        try:
            coll = databases.get_collection(db_id, cid)
            print(f"Collection {name} already exists")
        except AppwriteException:
            # Collection doesn't exist, create it
            result = databases.create_collection(
                db_id,
                cid,
                name,
                permissions=[],
                document_security=True
            )
            print(f"Created collection: {name}")
            coll = None
        
        # Get existing attributes if collection exists
        existing_keys = set()
        if coll:
            existing_keys = {a.get('key') for a in coll.get('attributes', []) if 'key' in a}
        
        # Create attributes
        for attribute in collection['attributes']:
            attribute_key = attribute['key']
            attribute_type = attribute['type']
            required = attribute.get('required', False)
            
            # Skip if attribute already exists
            if attribute_key in existing_keys:
                print(f"  Attribute {attribute_key} already exists")
                continue
            
            print(f"  Creating {attribute_type} attribute: {attribute_key}")
            
            try:
                if attribute_type == 'string':
                    result = databases.create_string_attribute(
                        db_id, 
                        cid, 
                        attribute_key, 
                        attribute['size'], 
                        required,
                        default=None,
                        array=False
                    )
                elif attribute_type == 'datetime':
                    result = databases.create_datetime_attribute(
                        db_id, 
                        cid, 
                        attribute_key, 
                        required,
                        default=None,
                        array=False
                    )
                elif attribute_type == 'integer':
                    result = databases.create_integer_attribute(
                        db_id, 
                        cid, 
                        attribute_key, 
                        required,
                        min=None,
                        max=None,
                        default=None,
                        array=False
                    )
                elif attribute_type == 'relationship':
                    result = databases.create_relationship_attribute(
                        db_id, 
                        cid, 
                        attribute['related_collection'], 
                        attribute['relationship_type'], 
                        attribute['two_way'], 
                        attribute.get('two_way_key'), 
                        attribute['on_delete']
                    )
                elif attribute_type == 'enum':
                    result = databases.create_enum_attribute(
                        db_id, 
                        cid, 
                        attribute_key, 
                        attribute['enum'], 
                        required,
                        default=None,
                        array=False
                    )
                elif attribute_type == 'boolean':
                    result = databases.create_boolean_attribute(
                        db_id, 
                        cid, 
                        attribute_key, 
                        required,
                        default=None,
                        array=False
                    )
                else:
                    raise ValueError(f'Unknown attribute type: {attribute_type}')
                print(f"    [SUCCESS] Created {attribute_key}")
            except AppwriteException as e:
                print(f"    [ERROR] Error creating {attribute_key}: {e.message}")

 
if __name__ == "__main__":   
    try:
        databases = Databases(client)
        
        # Create database and collections
        create_database(databases)
        create_collections(databases)

        time.sleep(5)  # Wait for collections to be fully set up
        
        print("\n=== Seeding data ===")
        
        # Seed collections with data
        seed_collection("training_data/sample_events.json", "events")
        seed_collection("training_data/sample_topics.json", "topics")
        seed_collection("training_data/sample_announcements.json", "announcements")
        seed_collection("training_data/sample_posts.json", "posts")
        seed_collection("training_data/sample_comments.json", "comments")
    
        
        # Seed likes
        print("\n=== Seeding likes ===")
        seed_collection("training_data/likes/sample_event_likes.json", "event_likes")
        seed_collection("training_data/likes/sample_post_likes.json", "post_likes")
        seed_collection("training_data/likes/sample_comment_likes.json", "comment_likes")
        
        # Create indexes
        print("\n=== Creating indexes ===")
        create_like_indexes()
        
        print("\n[SUCCESS] Database initialization complete!")
        
    except AppwriteException as e:
        print(f"\n[ERROR] Exception: {e.message}")
        print(f"   Type: {e.type if hasattr(e, 'type') else 'N/A'}")
        print(f"   Code: {e.code if hasattr(e, 'code') else 'N/A'}")
    except Exception as e:
        print(f"\n[ERROR] Unexpected error: {str(e)}")