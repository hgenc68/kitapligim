# -------------------------------------------------------------
# create_xr_video.ps1
# PowerShell betiği – Elinizdeki tek bir ekran görüntüsünden
# stereo‑side‑by‑side (left/right) bir XR video (MP4) üretir.
# -------------------------------------------------------------

# 1) ffmpeg yüklü mü? (https://ffmpeg.org/download.html)
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "\n❌ ffmpeg bulunamadı. Lütfen https://ffmpeg.org/download.html adresinden indirin ve PATH’e ekleyin."
    exit 1
}

# 2) Kullanmak istediğiniz kaynak resim(leri) belirleyin
#    Tek bir resim varsa, aynı resim sol ve sağ kanala kopyalanır.
#    Eğer iki ayrı resim (sol/right) varsa, aşağıdaki yolları değiştirin.
#    Örnek:  leftImage = 'screenshot_xr_1_home.png'
#            rightImage = 'screenshot_xr_1_home_right.png'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- Tek bir PNG kullanıyorsak ----
$leftImage  = Join-Path $scriptDir 'screenshot_xr_1_home.png'
$rightImage = $leftImage   # aynı dosyayı iki gözde de kullanacağız

# Eğer iki ayrı PNG varsa, aşağıdaki satırları düzenleyin:
# $leftImage  = Join-Path $scriptDir 'screenshot_xr_1_home_left.png'
# $rightImage = Join-Path $scriptDir 'screenshot_xr_1_home_right.png'

# 3) Geçici birleştirilmiş resim oluştur (side‑by‑side)
$mergedImg = Join-Path $scriptDir 'merged_xr_frame.png'
ffmpeg -y -i "$leftImage" -i "$rightImage" -filter_complex "[0][1]hstack=inputs=2" "$mergedImg"

# 4) Video parametreleri
$durationSec   = 30   # video uzunluğu (saniye)
$fps           = 30   # kare hızı

# 5) 3D (stereo side‑by‑side) video oluştur
$outputVideo3D = Join-Path $scriptDir 'xr_preview_3d.mp4'   # sessiz 3D video
ffmpeg -y -loop 1 -i "$mergedImg" -c:v libx264 -t $durationSec -r $fps -pix_fmt yuv420p -vf "scale=1920:1080" "$outputVideo3D"

# 6) 2D (tek göz) video oluştur
$outputVideo2D = Join-Path $scriptDir 'xr_preview_2d.mp4'   # sessiz 2D video
ffmpeg -y -loop 1 -i "$leftImage" -c:v libx264 -t $durationSec -r $fps -pix_fmt yuv420p -vf "scale=1920:1080" "$outputVideo2D"

# 7) Opsiyonel ses ekleme (audio.mp3 aynı klasörde ise)
$audioFile = Join-Path $scriptDir 'audio.mp3'
if (Test-Path "$audioFile") {
    $finalVideo3D = Join-Path $scriptDir 'xr_preview_3d_with_audio.mp4'
    $finalVideo2D = Join-Path $scriptDir 'xr_preview_2d_with_audio.mp4'
    ffmpeg -y -i "$outputVideo3D" -i "$audioFile" -c:v copy -c:a aac -shortest "$finalVideo3D"
    ffmpeg -y -i "$outputVideo2D" -i "$audioFile" -c:v copy -c:a aac -shortest "$finalVideo2D"
    Write-Host "\n✅ 3D Video (sesli) üretildi:\n   $finalVideo3D"
    Write-Host "\n✅ 2D Video (sesli) üretildi:\n   $finalVideo2D"
} else {
    Write-Host "\n✅ 3D Video (sessiz) üretildi:\n   $outputVideo3D"
    Write-Host "\n✅ 2D Video (sessiz) üretildi:\n   $outputVideo2D"
}

# 8) Temizlik (isteğe bağlı)
Remove-Item "$mergedImg" -Force -ErrorAction SilentlyContinue
