from google.cloud import storage
import os

def probar_conexion_gcp():
    # 1. Nombre de tu bucket (asegúrate que esté igual que en la consola)
    nombre_bucket = "safelima-evidencias" 
    
    try:
        print(f"--- Iniciando prueba de conexión a: {nombre_bucket} ---")
        
        # 2. Inicializar el cliente (usará tu sesión de 'gcloud auth application-default login')
        storage_client = storage.Client()
        
        # 3. Intentar obtener el bucket
        bucket = storage_client.get_bucket(nombre_bucket)
        
        # 4. Intentar crear un archivo de texto de prueba en la nube
        blob = bucket.blob("prueba_conexion.txt")
        blob.upload_from_string("¡Hola desde el backend de SafeLima! La conexión funciona.")
        
        print(f"✅ ÉXITO: Se ha subido el archivo 'prueba_conexion.txt' al bucket.")
        
        # 5. Listar lo que hay en el bucket para confirmar
        print("--- Archivos actuales en el bucket ---")
        blobs = storage_client.list_blobs(nombre_bucket)
        for b in blobs:
            print(f" - {b.name}")
            
    except Exception as e:
        print(f"❌ ERROR de conexión: {e}")
        print("\nSi sale error de '403 Forbidden', revisa que tengas el rol de 'Storage Object Admin' en IAM.")

if __name__ == "__main__":
    probar_conexion_gcp()