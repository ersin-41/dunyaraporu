import google.generativeai as genai
import requests
import os
import json
from dotenv import load_dotenv

load_dotenv()

class NewsAgent:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        if self.api_key:
            print(f"🔑 API Key yüklendi: {self.api_key[:8]}...{self.api_key[-4:]}")
            genai.configure(api_key=self.api_key)
            # Mevcut modelleri listele
            self._list_available_models()
            self.model_id = 'gemini-2.5-flash'
            print(f"✅ Gemini API Client başarıyla başlatıldı. Aktif model: {self.model_id}")
        else:
            print("❌ GEMINI_API_KEY bulunamadı! Hugging Face Secrets kontrol edin.")
            self.api_key = None
            self.model_id = None

    def _list_available_models(self):
        """Mevcut modelleri listele - teşhis amaçlı."""
        try:
            models = list(genai.list_models())
            print(f"📋 Mevcut model sayısı: {len(models)}")
            for m in models[:5]:
                print(f"   - {m.name}")
        except Exception as e:
            print(f"⚠️ Model listesi alınamadı: {e}")

    def _call_gemini_rest(self, prompt: str) -> str:
        """Direkt REST API çağrısı - SDK bypass."""
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={self.api_key}"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}]
        }
        headers = {"Content-Type": "application/json"}
        
        resp = requests.post(url, json=payload, headers=headers, timeout=30)
        
        if resp.status_code == 200:
            data = resp.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]
        else:
            # v1beta başarısız - v1 dene
            url_v1 = f"https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key={self.api_key}"
            resp2 = requests.post(url_v1, json=payload, headers=headers, timeout=30)
            if resp2.status_code == 200:
                data = resp2.json()
                return data["candidates"][0]["content"]["parts"][0]["text"]
            else:
                raise Exception(f"REST API Hatası [{resp.status_code}]: {resp.text[:300]}")

    def fetch_latest_news(self):
        """Dünya gündemindeki en güncel haberleri getirir. Liste döndürür."""
        if not self.api_key:
            return [{"title": "API Hatası", "summary": "GEMINI_API_KEY bulunamadı."}]

        try:
            prompt = """
            Dünya genelindeki en son ve önemli lojistik, kargo, tedarik zinciri ve teknoloji haberlerini bul.
            Sadece en güncel ve dikkat çekici 3-5 adet haber döndür.
            Yanıtı SADECE aşağıdaki JSON formatında ver (başka hiçbir metin ekleme):
            [
              {"title": "Haber Başlığı", "summary": "Kısa özet"},
              {"title": "Haber Başlığı 2", "summary": "Kısa özet 2"}
            ]
            """
            text = self._call_gemini_rest(prompt)
            clean = text.replace("```json", "").replace("```", "").strip()
            return json.loads(clean)
        except Exception as e:
            print(f"❌ Haber çekilemedi: {e}")
            return [{"title": "Bağlantı Hatası", "summary": f"Şu an haberlere ulaşılamıyor: {str(e)[:100]}"}]

    def generate_tiktok_script(self, news_content):
        """Haber içeriğinden TikTok için viral senaryo üretir."""
        if not self.api_key:
            return self._get_fallback_script()

        try:
            prompt = f"""
            Şu haber içeriğine dayanarak kısa, hızlı tempolu ve merak uyandıran bir TikTok video senaryosu hazırla.
            Haber: {news_content}
            
            Yanıtı SADECE aşağıdaki JSON formatında ver:
            {{
                "hook": "Dikkat çeken giriş cümlesi",
                "voiceover_text": "Videonun tamamında okunacak akıcı metin",
                "visual_descriptions": ["Görsel 1 için İngilizce arama terimi", "Görsel 2 için İngilizce arama terimi", "Görsel 3 için İngilizce arama terimi"]
            }}
            """
            text_response = self._call_gemini_rest(prompt)
            clean_json = text_response.replace("```json", "").replace("```", "").strip()
            return json.loads(clean_json)
        except Exception as e:
            print(f"⚠️ Senaryo üretilemedi: {e}")
            return self._get_fallback_script()

    def _get_fallback_script(self):
        return {
            "hook": "Lojistikte Neler Oluyor?",
            "voiceover_text": "Dünya lojistik piyasasında hareketli günler yaşanıyor.",
            "visual_descriptions": ["global logistics news", "shipping containers port", "supply chain technology"]
        }
