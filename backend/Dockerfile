FROM python:3.9

# Sistem bileşenlerini ve fontları kur
RUN apt-get update && apt-get install -y \
    imagemagick \
    ffmpeg \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    fontconfig \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# ImageMagick GÜVENLİK DUVARINI YIKIYORUZ: Tüm kısıtlamaları (none) READ|WRITE (oku/yaz) yap
RUN find /etc -name "policy.xml" -exec sed -i 's/rights="none"/rights="read|write"/g' {} +

WORKDIR /app
ENV PYTHONPATH=/app

# Bağımlılıkları yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Backend içeriğini kopyala
COPY . .

# Gerekli klasörleri oluştur ve izinlerini ayarla
RUN mkdir -p assets/scenes output && chmod -R 777 assets output

EXPOSE 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
