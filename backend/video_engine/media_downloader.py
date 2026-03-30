import os
import requests
from dotenv import load_dotenv

load_dotenv()

class MediaDownloader:
    def __init__(self):
        self.api_key = os.getenv("PEXELS_API_KEY")
        self.headers = {"Authorization": self.api_key}
        self.assets_dir = "assets/scenes"
        # Klasörün varlığından emin ol
        if not os.path.exists(self.assets_dir):
            os.makedirs(self.assets_dir, exist_ok=True)

    def download_media(self, query, scene_index, is_video=False):
        try:
            if not self.api_key:
                print("❌ Pexels API Anahtarı eksik!")
                return None

            # Pexels Türkçe anlamayabilir, genel lojistik terimlerini ekle
            search_query = f"{query} logistics news" 
            url = f"https://api.pexels.com/v1/search?query={search_query}&per_page=1&orientation=portrait"
            
            print(f"--- Pexels'ta aranıyor ({scene_index}): {search_query} ---")
            response = requests.get(url, headers=self.headers, timeout=10)
            
            if response.status_code != 200:
                print(f"❌ Pexels API Hatası ({response.status_code}): {response.text}")
                return None
                
            data = response.json()

            if data.get("photos") and len(data["photos"]) > 0:
                media_url = data["photos"][0]["src"]["large2x"]
                file_path = os.path.join(self.assets_dir, f"scene_{scene_index}.jpg")
                
                r = requests.get(media_url)
                with open(file_path, 'wb') as f:
                    f.write(r.content)
                print(f"✅ Görsel İndirildi: {file_path}")
                return file_path
            else:
                # Bulunamazsa 'stock' bir lojistik görseli çek
                print(f"⚠️ Uygun görsel bulunamadı, yedek görsel çekiliyor...")
                return self.download_media("global logistics industry", scene_index) if query != "global logistics industry" else None
        except Exception as e:
            print(f"❌ İndirme hatası: {e}")
            return None