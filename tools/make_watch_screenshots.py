#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TetsuLog Apple Watch App Store screenshots.
Apple Watch Ultra size 410x502 (accepted by App Store Connect for the watch set).
Renders the actual WatchTheme (kokutetsu: navy x cream x red) — must match the real app.
"""
import os, math
from PIL import Image, ImageDraw, ImageFont

SS = 3
OUT = "/home/user/ghost-club-lp/app/appstore-marketing-watch"
os.makedirs(OUT, exist_ok=True)
W, H = 410, 502

JP   = "/etc/alternatives/fonts-japanese-gothic.ttf"
CF   = "/mnt/skills/examples/canvas-design/canvas-fonts"
MONO = f"{CF}/IBMPlexMono-Bold.ttf"
SERIF= f"{CF}/IBMPlexSerif-Bold.ttf"

# WatchTheme palette (kokutetsu)
NAVY=(16,36,63); PAPER=(242,234,216); RED=(192,57,43)
CREAM=(240,230,207); GOLD=(201,162,75); INK=(16,36,63); INKSUB=(107,90,60)

_fc={}
def font(p,s):
    k=(p,int(s*SS))
    if k not in _fc: _fc[k]=ImageFont.truetype(p,int(s*SS))
    return _fc[k]
def has_cjk(s): return any(ord(c)>0x2E7F for c in s)

class C:
    def __init__(self):
        self.img=Image.new("RGB",(W*SS,H*SS),(0,0,0))
        self.d=ImageDraw.Draw(self.img,"RGBA")
    def vgrad(self,box,t,b):
        x0,y0,x1,y1=box; h=max(1,int((y1-y0)*SS))
        for i in range(h):
            f=i/h; col=tuple(int(t[j]+(b[j]-t[j])*f) for j in range(3))
            self.d.line([(int(x0*SS),int(y0*SS)+i),(int(x1*SS),int(y0*SS)+i)],fill=col)
    def rrect(self,box,r,fill=None,outline=None,width=1):
        self.d.rounded_rectangle([int(v*SS) for v in box],radius=int(r*SS),fill=fill,outline=outline,width=int(width*SS))
    def text(self,xy,s,p,size,fill,anchor="la",bold=0):
        fnt=font(JP if has_cjk(s) else p,size)
        self.d.text((xy[0]*SS,xy[1]*SS),s,font=fnt,fill=fill,anchor=anchor,
                    stroke_width=int(bold*SS),stroke_fill=fill)
    def save(self,name):
        self.img.resize((W,H),Image.LANCZOS).save(os.path.join(OUT,name),"PNG")
        print("saved",name)

def bg(c):
    c.vgrad([0,0,W,H],NAVY,(0,0,0))

def card(c,box):
    c.rrect(box,14,fill=PAPER)
    c.rrect(box,14,outline=(255,255,255,90),width=1)

def header(c):
    cx=W/2
    c.text((cx-58,30),"🚆",JP,15,RED,anchor="la")  # fallback if emoji missing harmless
    c.text((cx,34),"TETSULOG",MONO,15,CREAM,anchor="ma")

# ---- screens ----
def s_today(c):
    bg(c)
    c.text((W/2,40),"TETSULOG",MONO,15,CREAM,anchor="ma")
    # 今週 card
    b=[22,72,W-22,206]; card(c,b)
    c.text((40,86),"今 週",JP,13,INKSUB,bold=0)
    c.text((40,108),"8",SERIF,58,RED,anchor="la")
    c.text((104,150),"件",JP,18,INKSUB,anchor="la")
    c.text((W-40,150),"今月 23",MONO,15,INKSUB,anchor="ra")
    # 最後の遭遇 card
    b=[22,222,W-22,330]; card(c,b)
    c.text((40,234),"最後の遭遇",JP,12,INKSUB)
    c.text((40,256),"E235系 トウ04",JP,18,INK,bold=1)
    c.text((40,286),"山手線 · 東京",JP,13,INKSUB)
    c.text((40,306),"3時間前",MONO,11,INKSUB)
    # 記録ボタン
    b=[22,348,W-22,422]; c.rrect(b,14,fill=RED)
    c.text((W/2,372),"＋ 記録",JP,22,PAPER,anchor="ma",bold=1)
    c.save("01-watch-today.png")

def s_record(c):
    bg(c)
    c.text((W/2,40),"記 録",JP,20,CREAM,anchor="ma",bold=1)
    rows=[("形 式","E235系"),("編成番号","トウ04"),("駅","東京")]
    yy=78
    for k,v in rows:
        b=[22,yy,W-22,yy+78]; card(c,b)
        c.text((40,yy+14),k,JP,11,INKSUB)
        c.text((40,yy+34),v,MONO,20,INK)
        yy+=90
    b=[22,yy+4,W-22,yy+78]; c.rrect(b,14,fill=RED)
    c.text((W/2,yy+28),"記録する",JP,20,PAPER,anchor="ma",bold=1)
    c.save("02-watch-record.png")

def s_face(c):
    # 文字盤コンプリ風（黒地に時刻＋コンプリ）
    c.vgrad([0,0,W,H],(8,12,18),(0,0,0))
    c.text((W/2,70),"10:09",MONO,64,(240,245,250),anchor="ma")
    # complication chip
    b=[W/2-120,200,W/2+120,300]; c.rrect(b,18,fill=(20,28,40))
    c.rrect(b,18,outline=(95,208,255,120),width=1)
    c.text((W/2,222),"TETSULOG",MONO,12,(132,167,194),anchor="ma")
    c.text((W/2,244),"今週 8件",JP,22,(95,208,255),anchor="ma",bold=1)
    c.text((W/2,360),"文字盤に今週の遭遇数",JP,15,(150,170,190),anchor="ma")
    c.save("03-watch-complication.png")

for fn in (s_today, s_record, s_face):
    fn(C())
print("watch done", W, "x", H)
