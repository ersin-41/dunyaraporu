import os
import traceback
import re
import platform
import shutil
import PIL.Image

# MONKEY PATCH: Pillow >= 10.0.0 ile kaldırılan ANTIALIAS özelliğini MoviePy için yamıyoruz.
if not hasattr(PIL.Image, 'ANTIALIAS'):
    PIL.Image.ANTIALIAS = PIL.Image.LANCZOS

# Hem Windows hem de Linux için ImageMagick BINARY yolu otomatik belirlenir
IMAGEMAGICK_EXECUTABLE = ""

if platform.system() == "Windows":
    IMAGEMAGICK_EXECUTABLE = r"C:\Program Files\ImageMagick-7.1.2-Q16\magick.exe"
else:
    # Linux (Docker) ortamında path üzerinde ara
    IMAGEMAGICK_EXECUTABLE = shutil.which("magick") or shutil.which("convert") or "/usr/bin/convert"

# MoviePy bu environment variable'ı otomatik okur
os.environ["IMAGEMAGICK_BINARY"] = IMAGEMAGICK_EXECUTABLE

from moviepy.editor import (
    VideoFileClip, AudioFileClip, TextClip, CompositeVideoClip, 
    ColorClip, ImageClip, concatenate_videoclips
)
from datetime import datetime
import numpy as np

class VideoRenderer:
    def __init__(self):
        self.width = 1080
        self.height = 1920
        self.fps = 24 
        self.font = "DejaVu-Sans" if platform.system() != "Windows" else "Arial"
        print(f"\u2705 Renderer ba\u015flat\u0131ld\u0131. Font set: {self.font}")
        
    def create_zoom_effect(self, clip, zoom_speed=0.03):
        try:
            return clip.resize(lambda t: 1 + zoom_speed * t)
        except:
            return clip

    def render_tiktok_video(self, script_data: dict, audio_path: str, project_name: str) -> str:
        print(f"--- Video Render Ba\u015flad\u0131: {project_name} ---")
        today = datetime.now().strftime("%Y-%m-%d")
        output_dir = os.path.join("output", today, project_name)
        os.makedirs(output_dir, exist_ok=True)
        final_output_path = os.path.join(output_dir, f"video_{int(datetime.now().timestamp())}.mp4")

        try:
            audio = AudioFileClip(audio_path)
            total_duration = audio.duration
            scenes = script_data.get("visual_descriptions", script_data.get("scenes", []))
            
            if not scenes:
                scenes = ["global world news"]

            duration_per_scene = total_duration / len(scenes)
            scene_clips = []

            for i, description in enumerate(scenes):
                img_filename = f"scene_{i+1}.jpg"
                img_path = os.path.abspath(os.path.join("assets", "scenes", img_filename))
                
                if os.path.exists(img_path):
                    img_clip = ImageClip(img_path).set_duration(duration_per_scene)
                    img_clip = img_clip.resize(height=self.height)
                    if img_clip.w > self.width:
                        img_clip = img_clip.crop(x_center=img_clip.w/2, width=self.width)
                    img_clip = self.create_zoom_effect(img_clip)
                    scene_clips.append(img_clip)
            
            if not scene_clips:
                # E\u011fer hi\u00e7 g\u00f6rsel yoksa bo\u015f arka plan olu\u015ftur
                scene_clips.append(ColorClip(size=(self.width, self.height), color=(20, 20, 20)).set_duration(total_duration))

            background_video = concatenate_videoclips(scene_clips, method="compose")

            # Altyaz\u0131lar
            voiceover_text = script_data.get("voiceover_text", script_data.get("script", "B\u00fclten Haber Ak\u0131\u015f\u0131"))
            hook_text = script_data.get("hook", "D\u00dcNYA RAPORU")

            subtitle_segments = re.split(r'(?<=[.!?])\s+', voiceover_text.strip())
            subtitle_segments = [s for s in subtitle_segments if s.strip()]
            
            if not subtitle_segments:
                subtitle_segments = [voiceover_text]

            duration_per_segment = total_duration / len(subtitle_segments)
            all_text_clips = []

            try:
                # Hook (Kanca)
                header = TextClip(
                    hook_text.upper(),
                    fontsize=70, color='white', font=self.font,
                    bg_color='black', method='caption', size=(self.width * 0.9, None)
                ).set_duration(total_duration).set_position(('center', 180))
                all_text_clips.append(header)

                # Altyazılar
                for i, text in enumerate(subtitle_segments):
                    start_time = i * duration_per_segment
                    try:
                        sub = TextClip(
                            text.upper(),
                            fontsize=50, color='#FFD700', font=self.font,
                            method='caption', align='center', size=(self.width * 0.85, None),
                            stroke_color='black', stroke_width=1
                        ).set_start(start_time).set_duration(duration_per_segment).set_position(('center', self.height * 0.75))
                        all_text_clips.append(sub)
                    except Exception as sub_err:
                        print(f"⚠️ Tekil altyazı klibi hatası ({i}): {sub_err}")

                if all_text_clips:
                    final_video = CompositeVideoClip([background_video] + all_text_clips)
                else:
                    print("⚠️ Hiç altyazı klibi oluşturulamadı, sadece arka plan kullanılıyor.")
                    final_video = background_video
            except Exception as txt_err:
                print(f"❌ Altyazı katmanı oluşturulurken kritik hata: {txt_err}")
                print(traceback.format_exc())
                final_video = background_video

            # Render
            final_video = final_video.set_audio(audio)
            final_video.write_videofile(
                final_output_path, 
                fps=self.fps, 
                codec="libx264", 
                audio_codec="aac",
                threads=4,
                preset="ultrafast"
            )
            return final_output_path

        except Exception as global_err:
            print(f"\u274c GLOBAL RENDER HATASI: {traceback.format_exc()}")
            raise global_err