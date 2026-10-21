# -*- coding: utf-8 -*-
from PIL import Image, ImageDraw, ImageFilter
import math

def create_fec_icon():
    size = 512
    # 建立畫布 (RGBA 透明底)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. 繪製微陰影
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([36, 40, size - 36, size - 32], radius=110, fill=(0, 0, 0, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    img.paste(shadow, (0, 0), shadow)

    # 2. 繪製現代圓角漸層外框 (新北環保海藍盾牌底色)
    # 頂部 #184b72 (24, 75, 114) 到 底部 #1e6091 (30, 96, 145)
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(base)
    b_draw.rounded_rectangle([36, 36, size - 36, size - 36], radius=110, fill=(30, 96, 145, 255))
    
    # 內部繪製漸層
    for y in range(36, size - 36):
        ratio = (y - 36) / float(size - 72)
        r = int(24 * (1 - ratio) + 30 * ratio)
        g = int(75 * (1 - ratio) + 96 * ratio)
        b = int(114 * (1 - ratio) + 145 * ratio)
        # 用一條一條線微調漸層感
        b_draw.line([(40, y), (size - 40, y)], fill=(r, g, b, 255))
        
    # 再次裁切圓角遮罩
    mask = Image.new("L", (size, size), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle([36, 36, size - 36, size - 36], radius=110, fill=255)
    img.paste(base, (0, 0), mask)

    # 3. 繪製核心標誌：結合「固定源淨化循環」與「綠色環保葉片」
    # A. 綠色活力葉片 (象徵環保減碳與清淨空氣)
    leaf = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    l_draw = ImageDraw.Draw(leaf)
    
    # 葉片多邊形 (平滑流線)
    leaf_points = [
        (256, 110),
        (330, 150),
        (370, 230),
        (350, 320),
        (280, 390),
        (256, 410),
        (220, 370),
        (170, 310),
        (150, 220),
        (180, 150)
    ]
    # 漸層綠色葉片: #10b981 (16, 185, 129)
    l_draw.polygon(leaf_points, fill=(16, 185, 129, 255))
    
    # 葉脈中心線 (潔白高光)
    l_draw.line([(256, 130), (256, 380)], fill=(255, 255, 255, 200), width=12)
    l_draw.line([(256, 220), (320, 180)], fill=(255, 255, 255, 180), width=8)
    l_draw.line([(256, 260), (190, 220)], fill=(255, 255, 255, 180), width=8)
    l_draw.line([(256, 300), (310, 270)], fill=(255, 255, 255, 180), width=8)

    # B. 環繞的清淨空氣環 (象徵溢散源防護管考)
    # 藍白光環弧線
    l_draw.arc([100, 100, 412, 412], start=210, end=40, fill=(255, 255, 255, 240), width=22)
    # 光環端點箭頭/微風水滴
    l_draw.ellipse([375, 135, 405, 165], fill=(255, 255, 255, 255))

    img.paste(leaf, (0, 0), leaf)

    # 4. 輸出檔案
    # A. 輸出 192x192 apple-touch-icon.png
    touch_icon = img.resize((192, 192), Image.Resampling.LANCZOS)
    touch_icon.save(r"D:\NTPC_FEC\apple-touch-icon.png", format="PNG")

    # B. 輸出多尺寸合一 favicon.ico (16, 32, 48, 64, 128)
    sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128)]
    img.save(r"D:\NTPC_FEC\favicon.ico", format="ICO", sizes=sizes)
    print("專屬 favicon.ico 與 apple-touch-icon.png 產製完成！")

if __name__ == "__main__":
    create_fec_icon()
