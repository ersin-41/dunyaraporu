import PIL.Image
# KR\u0130T\u0130K YAMA: Her \u015feyden \u00f6nce ANTIALIAS hatas\u0131n\u0131 m\u00fch\u00fcrle
if not hasattr(PIL.Image, 'ANTIALIAS'):
    PIL.Image.ANTIALIAS = PIL.Image.LANCZOS
    print("\u2705 PIL.Image.ANTIALIAS Patch Applied")

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict
import os
import sys
import json
import re
import traceback
import asyncio
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Mod\u00fcllerin tan\u0131nmas\u0131 i\u00e7in k\u00f6k dizini sys.path'e ekle
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# Gerekli agent ve engine mod\u00fcllerini i\u00e7eri aktar
try:
    from agents.news_agent import NewsAgent
    from agents.voice_agent import VoiceAgent
    from video_engine.renderer import VideoRenderer
    from video_engine.media_downloader import MediaDownloader
    print("\u2705 T\u00fcm mod\u00fcller ba\u015far\u0131yla y\u00fcklendi.")
except ImportError as e:
    print(f"\u274c Mod\u00fcl y\u00fckleme hatas\u0131: {e}")
    # Kritik hata durumunda sistemi durdurma, loglamaya devam et

load_dotenv()

app = FastAPI(title="D\u00fcnya Raporu AI Content Automation")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("output", exist_ok=True)
app.mount("/output", StaticFiles(directory="output"), name="output")

# Servisleri ba\u015flat
try:
    news_agent = NewsAgent()
    voice_agent = VoiceAgent()
    video_renderer = VideoRenderer()
    media_downloader = MediaDownloader()
except Exception as e:
    print(f"\u274c Servis ba\u015flatma hatas\u0131: {e}")

class ScriptRequest(BaseModel):
    news_content: str

class AudioRequest(BaseModel):
    text: str
    project_name: str

class RenderRequest(BaseModel):
    script_data: dict
    audio_path: str
    project_name: str

@app.get("/")
async def root():
    has_gemini = "SET" if os.getenv("GEMINI_API_KEY") else "MISSING"
    has_pexels = "SET" if os.getenv("PEXELS_API_KEY") else "MISSING"
    return {
        "status": "D\u00fcnya Raporu Sistemi Aktif", 
        "v": "1.2.2 - Final Shield Edition",
        "api_status": {"gemini": has_gemini, "pexels": has_pexels}
    }

@app.get("/news/latest")
async def get_latest_news():
    try:
        news = news_agent.fetch_latest_news()
        return {"news": news}
    except Exception as e:
        print(f"\u274c Haber \u00e7ekme hatas\u0131: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Haberler \u00e7ekilemedi: {str(e)}")

@app.post("/scripts/generate")
async def generate_script(request: ScriptRequest):
    try:
        if not news_agent.api_key:
            raise ValueError("GEMINI_API_KEY eksik! L\u00fctfen Hugging Face Secrets k\u0131sm\u0131ndan tan\u0131mlay\u0131n.")

        print(f"--- Senaryo \u00dcretimi Ba\u015flad\u0131: {request.news_content[:50]}... ---")
        script_data = news_agent.generate_tiktok_script(request.news_content)
        
        # Uyumluluk k\u00f6pr\u00fcs\u00fc
        script_data["script"] = script_data.get("voiceover_text", script_data.get("script", "Senaryo \u00fcretilemedi."))
        script_data["scenes"] = script_data.get("visual_descriptions", script_data.get("scenes", []))
            
        # G\u00f6rsel indirme
        scenes = script_data.get("visual_descriptions", [])
        for i, desc in enumerate(scenes):
            try:
                media_downloader.download_media(desc, i + 1, is_video=False)
            except Exception as downloader_err:
                print(f"\u26a0\ufe0f G\u00f6rsel {i+1} indirilemedi: {downloader_err}")
                continue
            
        print("\u2705 Senaryo ve G\u00f6rseller ba\u015far\u0131yla haz\u0131rland\u0131.")
        return {"script_data": script_data}

    except Exception as e:
        error_msg = f"Senaryo \u00fcretim hatas\u0131: {str(e)}"
        print(f"\u274c {error_msg}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=error_msg)

@app.post("/generate-audio")
async def generate_audio(request: AudioRequest):
    try:
        file_path = await voice_agent.generate_audio(request.text, request.project_name)
        return {"file_path": file_path}
    except Exception as e:
        print(f"\u274c Ses \u00fcretim hatas\u0131: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/render-video")
async def render_video(request: RenderRequest):
    try:
        file_path = video_renderer.render_tiktok_video(
            request.script_data, 
            request.audio_path, 
            request.project_name
        )
        return {"video_path": file_path}
    except Exception as e:
        print(f"\u274c Video render hatas\u0131: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run(app, host="0.0.0.0", port=port)