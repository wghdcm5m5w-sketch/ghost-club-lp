#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TetsuLog App Store marketing screenshots.
Pure-PIL renderer (no browser / no SVG rasterizer available in this env).
Renders at 2x supersample then downscales (LANCZOS) for crisp edges.
Japanese: IPAGothic. Latin/mono: IBM Plex / Geist (canvas-fonts).
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

SS = 2  # supersample
OUT = "/home/user/ghost-club-lp/app/appstore-marketing"
os.makedirs(OUT, exist_ok=True)

JP   = "/etc/alternatives/fonts-japanese-gothic.ttf"
CF   = "/mnt/skills/examples/canvas-design/canvas-fonts"
MONO = f"{CF}/IBMPlexMono-Bold.ttf"
MONOR= f"{CF}/IBMPlexMono-Regular.ttf"
GEIST= f"{CF}/GeistMono-Bold.ttf"
SERIF= f"{CF}/IBMPlexSerif-Bold.ttf"

# ---- palette (from app Theme) ----
BG_T=(17,21,29); BG_B=(7,9,14)
CYAN=(95,208,255); CYANDIM=(132,167,194)
CREAM=(236,224,194); CINK=(37,27,16); CINKSUB=(122,106,72)
RED=(216,72,58); GOLD=(212,175,90)
SURF=(22,27,36); SURF2=(28,35,48); EDGE=(42,49,61)
TX=(231,236,243); TXD=(148,161,178)
NAVY=(14,20,32); BLUE=(29,78,134); GREEN=(44,106,60); AMBER=(255,207,74)

_fc={}; _meta={}
def font(path,size):
    k=(path,int(size*SS))
    if k not in _fc:
        f=ImageFont.truetype(path,int(size*SS)); _fc[k]=f; _meta[id(f)]=(path,size)
    return _fc[k]

def _has_cjk(s):
    return any(ord(ch)>0x2E7F for ch in s)

class C:
    def __init__(self,W,H):
        self.W=W; self.H=H
        self.img=Image.new("RGB",(W*SS,H*SS),BG_B)
        self.d=ImageDraw.Draw(self.img,"RGBA")
    def _b(self,box): return [int(v*SS) for v in box]
    def vgrad(self,box,top,bot):
        x0,y0,x1,y1=box
        h=max(1,int((y1-y0)*SS))
        for i in range(h):
            t=i/h
            col=tuple(int(top[j]+(bot[j]-top[j])*t) for j in range(3))
            self.d.line([(int(x0*SS),int(y0*SS)+i),(int(x1*SS),int(y0*SS)+i)],fill=col)
    def rrect(self,box,r,fill=None,outline=None,width=1):
        self.d.rounded_rectangle(self._b(box),radius=int(r*SS),fill=fill,outline=outline,width=int(width*SS))
    def rect(self,box,fill=None,outline=None,width=1):
        self.d.rectangle(self._b(box),fill=fill,outline=outline,width=int(width*SS))
    def line(self,pts,fill,width=1):
        self.d.line([(int(x*SS),int(y*SS)) for x,y in pts],fill=fill,width=int(width*SS))
    def ellipse(self,box,fill=None,outline=None,width=1):
        self.d.ellipse(self._b(box),fill=fill,outline=outline,width=int(width*SS))
    def poly(self,pts,fill=None,outline=None,width=1):
        self.d.polygon([(int(x*SS),int(y*SS)) for x,y in pts],fill=fill,outline=outline,width=int(width*SS))
    def arc(self,box,a0,a1,fill,width):
        self.d.arc(self._b(box),a0,a1,fill=fill,width=int(width*SS))
    def text(self,xy,s,fnt,fill,anchor="la",bold=0,track=0):
        # CJKを含む文字列がLatin専用フォントなら、同サイズのIPAGothicに自動切替（豆腐防止）
        if _has_cjk(s):
            path,size=_meta.get(id(fnt),(JP,0))
            if path!=JP and size: fnt=font(JP,size)
        x,y=xy[0]*SS,xy[1]*SS
        if track==0:
            self.d.text((x,y),s,font=fnt,fill=fill,anchor=anchor,
                        stroke_width=int(bold*SS),stroke_fill=fill)
        else:
            # manual letter spacing (anchor left baseline-ish; use top-left)
            cx=x
            for ch in s:
                self.d.text((cx,y),ch,font=fnt,fill=fill,anchor="la",
                            stroke_width=int(bold*SS),stroke_fill=fill)
                w=self.d.textlength(ch,font=fnt)
                cx+=w+track*SS
    def tlen(self,s,fnt,track=0):
        w=self.d.textlength(s,font=fnt)
        if track: w+=track*SS*max(0,len(s))
        return w/SS
    def save(self,name):
        out=self.img.resize((self.W,self.H),Image.LANCZOS)
        out.save(os.path.join(OUT,name),"PNG")
        print("saved",name,out.size)

# ---------- shared marketing chrome ----------
def backdrop(c):
    c.vgrad([0,0,c.W,c.H],BG_T,BG_B)
    # faint blueprint grid
    for gx in range(0,c.W+1,76):
        c.line([(gx,0),(gx,c.H)],(150,200,240,12),1)
    for gy in range(0,c.H+1,76):
        c.line([(0,gy),(c.W,gy)],(150,200,240,12),1)
    # top glow
    glow=Image.new("RGBA",(c.W*SS,c.H*SS),(0,0,0,0))
    gd=ImageDraw.Draw(glow)
    cx=int(c.W*0.5*SS); cy=int(-0.04*c.H*SS); rad=int(0.62*c.W*SS)
    for i in range(rad,0,-int(rad/60)):
        a=int(26*(i/rad))
        gd.ellipse([cx-i,cy-i,cx+i,cy+i],fill=(40,70,110,max(0,26-a)))
    c.img.paste(Image.alpha_composite(c.img.convert("RGBA"),glow).convert("RGB"),(0,0))
    c.d=ImageDraw.Draw(c.img,"RGBA")

def header(c, kicker, l1, l2=None):
    m=90
    c.text((m,140),kicker,font(GEIST,30),CYAN,track=10)
    c.line([(m,196),(m+ c.tlen(kicker,font(GEIST,30),10),196)],(95,208,255,90),2)
    c.text((m,224),l1,font(JP,80),TX,bold=2)
    if l2: c.text((m,330),l2,font(JP,80),TX,bold=2)

def phone(c, top=560, w=980, h=1980):
    x0=(c.W-w)//2; y0=top; x1=x0+w; y1=y0+h
    # bezel
    c.rrect([x0-10,y0-10,x1+10,y1+10],74, fill=(20,24,30))
    c.rrect([x0,y0,x1,y1],66, fill=(8,10,14))
    inner=[x0+14,y0+14,x1-14,y1-14]
    # notch
    nw=190
    c.rrect([(c.W-nw)//2,y0+14,(c.W+nw)//2,y0+58],18,fill=(0,0,0))
    return inner  # screen box (logical)

def statusbar(c,box,light=True):
    x0,y0,x1,_=box
    col=TX if light else CINK
    c.text((x0+34,y0+30),"9:41",font(MONO,30),col)
    # signal/wifi/batt as simple glyphs
    bx=x1-150
    for i,hh in enumerate([10,16,22,28]):
        c.rect([bx+i*12,y0+52-hh,bx+i*12+8,y0+52],fill=col)
    c.rrect([x1-150+60,y0+30,x1-150+108,y0+54],4,outline=col,width=2)
    c.rect([x1-150+110,y0+37,x1-150+114,y0+47],fill=col)
    c.rect([x1-150+62,y0+32,x1-150+62+38,y0+52],fill=CYAN if light else GREEN)

def tabbar(c,box,active=0):
    x0,_,x1,y1=box
    th=128
    c.rect([x0,y1-th,x1,y1],fill=(8,10,14,235))
    c.line([(x0,y1-th),(x1,y1-th)],(150,200,240,30),1)
    labels=["図鑑","記録","地図","設定"]
    n=len(labels); seg=(x1-x0)/n
    for i,lb in enumerate(labels):
        cx=x0+seg*(i+0.5)
        col=CYAN if i==active else (130,140,155)
        c.ellipse([cx-16,y1-th+26,cx+16,y1-th+58],outline=col,width=3)
        c.text((cx,y1-th+74),lb,font(JP,22),col,anchor="ma")

# ---------- app-UI illustrations ----------
def car_diagram(c, box, kinds, color):
    x0,y0,x1,y1=box
    n=len(kinds); gap=6; cw=((x1-x0)-gap*(n-1))/n
    for i,k in enumerate(kinds):
        bx0=x0+i*(cw+gap); bx1=bx0+cw
        bt=y0+(y1-y0)*0.28; bb=y0+(y1-y0)*0.74
        if k=="cab":
            if i==n-1:
                c.poly([(bx0,bt),(bx1-12,bt),(bx1,bt+10),(bx1,bb),(bx0,bb)],outline=color,width=2)
            else:
                c.poly([(bx0+12,bt),(bx1,bt),(bx1,bb),(bx0,bb),(bx0,bt+10)],outline=color,width=2)
        elif k=="motor":
            c.rrect([bx0,bt,bx1,bb],5,outline=color,width=2)
            mx=(bx0+bx1)/2
            c.line([(mx-12,bt),(mx-4,bt-10),(mx+4,bt-10),(mx+12,bt)],color,2)
        elif k=="loco":
            ins=(bx1-bx0)*0.16
            c.rrect([bx0+ins,bt,bx1-ins,bb],4,outline=color,width=2)
            c.rect([bx0,bt+4,bx0+ins,bb],outline=color,width=2)
            c.rect([bx1-ins,bt+4,bx1,bb],outline=color,width=2)
        else:
            c.rrect([bx0,bt,bx1,bb],5,outline=color,width=2)
        # windows
        ww=(bx1-bx0); wins=max(3,int(ww/22))
        for w in range(wins):
            wx=bx0+ (bx1-bx0)*0.16 + (ww*0.68)/wins*w + 4
            c.rect([wx,bt+(bb-bt)*0.2,wx+(ww*0.68)/wins-6,bt+(bb-bt)*0.5],fill=color+(110,))
        # bogies
        for f in (0.24,0.76):
            wx=bx0+(bx1-bx0)*f
            c.ellipse([wx-6,bb+6,wx+6,bb+18],outline=color,width=2)

def card(c, box, accent=True, aged=False):
    x0,y0,x1,y1=box
    c.rrect(box,22,fill=SURF if not aged else (20,24,32))
    c.rrect(box,22,outline=EDGE,width=2)
    if accent:
        c.rrect([x0,y0,x0+8,y1],4,fill=(110,124,140) if aged else CYAN)

def ticket(c, box, edge=RED, aged=False):
    x0,y0,x1,y1=box
    base = (220,199,148) if aged else CREAM
    c.rrect(box,10,fill=base)
    # jimon hatch
    for dx in range(int(x0-(y1-y0)),int(x1),14):
        c.line([(dx,y0),(dx+(y1-y0),y1)],(60,45,20,16),1)
    c.rrect([x0+8,y0+8,x1-8,y1-8],6,outline=(70,52,26,120),width=2)
    c.rect([x0,y0,x0+12,y1],fill=edge)

def gauge(c, cx, cy, r, ratio):
    box=[cx-r,cy-r,cx+r,cy+r]
    c.arc(box,180,360,EDGE,16)
    c.arc(box,180,180+180*ratio,CYAN,16)

# ===================================================================
# SCREENS
# ===================================================================
def s_zukan(c):
    backdrop(c); header(c,"COLLECTION","出会った編成が、","図鑑になる。")
    sb=phone(c); statusbar(c,sb); x0,y0,x1,y1=sb
    pad=40; cx0=x0+pad; cx1=x1-pad; yy=y0+96
    c.text((cx0,yy),"TETSULOG",font(GEIST,22),CYANDIM,track=6); yy+=34
    c.text((cx0,yy),"図鑑",font(JP,56),CREAM,bold=1)
    c.text((cx1,yy+18),"46%",font(MONO,40),CYANDIM,anchor="ra"); yy+=104
    data=[("E235系","JR東日本 · 山手線",["cab","motor","plain","motor","cab"],CYAN,"24/50",0.48,False),
          ("E353系","JR東日本 · あずさ",["cab","motor","plain","motor","cab"],CYAN,"13/26",0.50,False),
          ("EF65形","JR貨物 · 電気機関車",["loco"],CYAN,"31回",0.62,False),
          ("E217系","JR東日本 · 廃車進行",["cab","motor","plain","cab"],GOLD,"07/07",1.0,True)]
    ch=232
    for name,op,kinds,col,ratio,frac,aged in data:
        b=[cx0,yy,cx1,yy+ch]; card(c,b,aged=aged)
        c.text((cx0+34,yy+24),name,font(JP,40),TX if not aged else (226,210,170),bold=1)
        if aged:
            c.text((cx1-34,yy+30),"廃車",font(JP,22),GOLD,anchor="ra")
        else:
            c.ellipse([cx1-34,yy+30,cx1-18,yy+46],fill=col)
        c.text((cx0+34,yy+78),op,font(JP,24),TXD)
        car_diagram(c,[cx0+34,yy+112,cx1-34,yy+158],kinds,col)
        # gauge bar
        c.rrect([cx0+34,yy+182,cx1-120,yy+192],5,fill=EDGE)
        if frac>0: c.rrect([cx0+34,yy+182,cx0+34+(cx1-120-(cx0+34))*frac,yy+192],5,fill=col)
        c.text((cx1-34,yy+176),ratio,font(MONO,26),col if aged else CYANDIM,anchor="ra")
        yy+=ch+24
    tabbar(c,sb,0); c.save("01-zukan.png")

def s_kiroku(c):
    backdrop(c); header(c,"LOG","記録は、","一枚の硬券になる。")
    sb=phone(c); statusbar(c,sb); x0,y0,x1,y1=sb
    pad=40; cx0=x0+pad; cx1=x1-pad; yy=y0+96
    c.text((cx0,yy),"TETSULOG",font(GEIST,22),CYANDIM,track=6); yy+=34
    c.text((cx0,yy),"記録",font(JP,56),CREAM,bold=1); yy+=96
    rows=[("山手線","JR東日本 · 通勤型","E235系  トウ04","東京",RED,"定期",False),
          ("あずさ","JR東日本 · 中央本線","E353系  S204","新宿",RED,"特急",False),
          ("総武緩行線","JR東日本 · 通勤型","E231系  ミツB27","秋葉原",BLUE,"定期",False),
          ("201系 さよなら","JR東日本 · 中央線","201系  H4","豊田",RED,"ラストラン",True)]
    th=250
    for ln,op,model,stn,edge,kind,aged in rows:
        b=[cx0,yy,cx1,yy+th]; ticket(c,b,edge=edge,aged=aged)
        c.text((cx0+40,yy+26),ln,font(JP,44),CINK,bold=1)
        c.text((cx0+40,yy+82),op,font(JP,22),CINKSUB)
        # dating stamp
        c.text((cx1-30,yy+30),"26.-6.13",font(MONO,26),(58,47,78),anchor="ra")
        c.text((cx0+40,yy+120),model,font(MONO,30),CINK)
        c.text((cx0+40,yy+166),stn,font(JP,28),CINK,bold=1)
        # kind chip
        kw=c.tlen(kind,font(JP,22))+28
        c.rrect([cx1-30-kw,yy+162,cx1-30,yy+196],4,outline=edge,width=2)
        c.text((cx1-30-kw/2,yy+168),kind,font(JP,22),edge,anchor="ma")
        c.text((cx0+40,yy+210),"下車前途無効 ・ 通用発売当日限り",font(JP,16),(154,135,95))
        c.text((cx1-30,yy+208),"No.260613-0042",font(MONOR,18),CINKSUB,anchor="ra")
        yy+=th+22
    tabbar(c,sb,1); c.save("02-kiroku.png")

def s_detail(c):
    backdrop(c); header(c,"DETAIL","その一本を、","克明に残す。")
    sb=phone(c); statusbar(c,sb); x0,y0,x1,y1=sb
    pad=40; cx0=x0+pad; cx1=x1-pad; yy=y0+110
    # big ticket
    th=520; b=[cx0,yy,cx1,yy+th]; ticket(c,b,edge=BLUE)
    c.text((cx0+44,yy+34),"山手線",font(JP,64),CINK,bold=1)
    c.text((cx0+44,yy+112),"JR東日本 · 通勤型 E系",font(JP,24),CINKSUB)
    c.text((cx1-34,yy+40),"26.-6.13",font(MONO,30),(58,47,78),anchor="ra")
    c.text((cx0+44,yy+158),"E235系  トウ04編成",font(MONO,38),CINK)
    c.line([(cx0+44,yy+220),(cx1-34,yy+220)],(70,52,26,110),2)
    grid=[("遭遇駅","東京 (JY01)"),("列車番号","0512G 内回り"),
          ("車番","クハE235-4"),("天気","快晴"),
          ("種別","定期"),("収集","04/50編成")]
    gx=cx0+44; gy=yy+244; colw=(cx1-34-gx)/2
    for i,(k,v) in enumerate(grid):
        px=gx+colw*(i%2); py=gy+ (i//2)*86
        c.text((px,py),k,font(MONO,20),CINKSUB)
        c.text((px,py+26),v,font(JP,30),CINK,bold=1)
    c.line([(cx0+44,yy+th-66),(cx1-34,yy+th-66)],(70,52,26,110),2)
    c.text((cx0+44,yy+th-50),"様式 (2) 図 — 0042",font(MONOR,20),CINKSUB)
    c.text((cx1-34,yy+th-50),"No.260613-0042",font(MONOR,20),CINKSUB,anchor="ra")
    yy+=th+30
    # attachment dark card (photo + audio)
    ah=300; b=[cx0,yy,cx1,yy+ah]; card(c,b,accent=False)
    c.vgrad([cx0+30,yy+30,cx0+ (cx1-cx0)/2-15,yy+ah-30],(51,72,92),(28,39,51))
    c.rect([cx0+30,yy+30,cx0+(cx1-cx0)/2-15,yy+ah-30],outline=(150,200,240,40),width=2)
    c.text((cx0+46,yy+ah-60),"DSC_4821 · クハE235-4",font(MONOR,18),(190,210,230))
    # audio waveform
    awx=cx0+(cx1-cx0)/2+15
    c.text((awx,yy+40),"走行音 · VVVF 0'48\"",font(MONOR,20),CYANDIM)
    import random; random.seed(3)
    bw=(cx1-30-awx)/22
    for i in range(22):
        hh=random.randint(14,70)
        c.rect([awx+i*bw,yy+ah/2-hh/2,awx+i*bw+bw*0.6,yy+ah/2+hh/2],fill=CYAN+(200,))
    tabbar(c,sb,1); c.save("03-detail.png")

def s_scan(c):
    backdrop(c); header(c,"OCR SCAN · PRO","撮るだけで、","編成番号を読み取る。")
    sb=phone(c); statusbar(c,sb); x0,y0,x1,y1=sb
    pad=40; cx0=x0+pad; cx1=x1-pad; yy=y0+96
    c.text((cx0,yy),"きっぷを切る",font(JP,52),CREAM,bold=1); yy+=92
    # camera viewfinder
    vh=560; b=[cx0,yy,cx1,yy+vh];
    c.vgrad(b,(26,32,42),(12,16,22)); c.rrect(b,18,outline=EDGE,width=2)
    # train hint
    car_diagram(c,[cx0+60,yy+150,cx1-60,yy+260],["cab","motor","plain","cab"],(120,150,175))
    # scan frame
    fx0,fy0,fx1,fy1=cx0+220,yy+330,cx1-220,yy+430
    for (ax,ay,bx,by) in [(fx0,fy0,fx0+40,fy0),(fx0,fy0,fx0,fy0+40),
                          (fx1,fy0,fx1-40,fy0),(fx1,fy0,fx1,fy0+40),
                          (fx0,fy1,fx0+40,fy1),(fx0,fy1,fx0,fy1-40),
                          (fx1,fy1,fx1-40,fy1),(fx1,fy1,fx1,fy1-40)]:
        c.line([(ax,ay),(bx,by)],CYAN,4)
    c.text(((fx0+fx1)/2,(fy0+fy1)/2-26),"トウ04",font(MONO,52),CYAN,anchor="ma")
    c.line([(fx0,(fy0+fy1)/2+34),(fx1,(fy0+fy1)/2+34)],(95,208,255,120),2)
    c.rrect([cx1-150,yy+30,cx1-30,yy+78],8,fill=RED)
    c.text((cx1-90,yy+40),"PRO",font(GEIST,26),CREAM,anchor="ma",track=2)
    yy+=vh+34
    # result row
    for lab,val in [("形式","E235系"),("編成番号","トウ04"),("遭遇駅 ・ 路線","東京 / 山手線")]:
        b=[cx0,yy,cx1,yy+96]; card(c,b,accent=False)
        c.text((cx0+34,yy+22),lab,font(JP,22),CYANDIM)
        c.text((cx0+34,yy+50),val,font(MONO,34),TX)
        yy+=96+18
    yy+=14
    # 発券ボタン（半券型・ミシン目ノッチ）
    bh=118; b=[cx0,yy,cx1,yy+bh]
    c.rrect(b,16,fill=RED)
    c.ellipse([cx0-16,yy+bh/2-16,cx0+16,yy+bh/2+16],fill=(8,10,14))
    c.ellipse([cx1-16,yy+bh/2-16,cx1+16,yy+bh/2+16],fill=(8,10,14))
    c.text(((cx0+cx1)/2,yy+bh/2),"発 券",font(JP,42),CREAM,anchor="mm",bold=1)
    tabbar(c,sb,1); c.save("04-scan.png")

def s_map(c):
    backdrop(c); header(c,"MAP","あなたの足跡を、","製図する。")
    sb=phone(c); statusbar(c,sb,light=True); x0,y0,x1,y1=sb
    # dark map area fills the screen
    mb=[x0,y0,x1,y1]
    c.vgrad([x0,y0,x1,y1],(14,23,34),(7,10,15))
    for gx in range(int(x0),int(x1),58):
        c.line([(gx,y0),(gx,y1)],(150,200,240,18),1)
    for gy in range(int(y0),int(y1),58):
        c.line([(x0,gy),(x1,gy)],(150,200,240,18),1)
    cx=(x0+x1)/2; cy=(y0+y1)/2
    # loop + radials (glow then line)
    def gline(pts,col,w):
        c.line(pts,col+(50,),w+8); c.line(pts,col,w)
    # loop
    import math as M
    loop=[ (cx+ M.cos(t)*230, cy-120+ M.sin(t)*300) for t in [i/40*2*M.pi for i in range(41)]]
    c.line(loop,(154,205,50,50),16); c.line(loop,(154,205,50),6)
    gline([(cx,cy-420),(cx-260,cy-520),(cx-460,cy-600)],(243,152,0),6)
    gline([(cx,cy+180),(cx+40,cy+460),(cx,cy+760)],(54,176,224),6)
    gline([(cx+230,cy-120),(cx+520,cy-180)],(227,192,0),6)
    gline([(cx-300,cy-120),(cx-520,cy-260),(cx-560,cy-60)],(89,195,106),5)
    # abandoned dashed
    for i in range(0,18,2):
        p0=(cx-120+i*8, cy+120+i*22); p1=(cx-120+(i+1)*8, cy+120+(i+1)*22)
        c.line([p0,p1],(110,125,140),4)
    # stations
    for (sx,sy,glow) in [(cx,cy-420,True),(cx+230,cy-120,False),(cx,cy+180,False),(cx-300,cy-120,True)]:
        if glow:
            c.ellipse([sx-26,sy-26,sx+26,sy+26],fill=(95,208,255,60))
            c.ellipse([sx-13,sy-13,sx+13,sy+13],fill=CYAN,outline=(255,255,255),width=3)
        else:
            c.ellipse([sx-11,sy-11,sx+11,sy+11],fill=(11,15,21),outline=(207,224,240),width=3)
    # shooting spot diamond + wedge
    sx,sy=cx+300,cy+260
    c.poly([(sx,sy-30),(sx+22,sy),(sx,sy+30),(sx-22,sy)],fill=(255,207,74,60))
    c.poly([(sx,sy-13),(sx+13,sy),(sx,sy+13),(sx-13,sy)],fill=AMBER,outline=(11,15,21),width=2)
    c.text((cx+18,cy-446),"東京 JY01",font(MONO,22),(174,191,208))
    # compass
    c.ellipse([x1-96,y0+96,x1-40,y0+152],fill=(8,12,18,200),outline=(150,200,240,120),width=2)
    c.poly([(x1-68,y0+104),(x1-60,y0+126),(x1-68,y0+120),(x1-76,y0+126)],fill=CYAN)
    c.text((x1-68,y0+128),"N",font(MONO,16),(207,224,240),anchor="ma")
    # bottom sheet legend
    bh=150
    c.rect([x0,y1-bh,x1,y1],fill=(8,10,14,235))
    c.line([(x0,y1-bh),(x1,y1-bh)],(150,200,240,40),1)
    items=[("38","踏破"),("212","遭遇駅"),("23","撮影地"),("4,820","乗車km")]
    seg=(x1-x0)/len(items)
    for i,(v,k) in enumerate(items):
        mx=x0+seg*(i+0.5)
        c.text((mx,y1-bh+34),v,font(MONO,40),CYAN,anchor="ma")
        c.text((mx,y1-bh+90),k,font(JP,24),TXD,anchor="ma")
    c.save("05-map.png")

def s_stats(c):
    backdrop(c); header(c,"STATISTICS","数字が、","鉄道人生を語る。")
    sb=phone(c); statusbar(c,sb); x0,y0,x1,y1=sb
    pad=40; cx0=x0+pad; cx1=x1-pad; yy=y0+96
    c.text((cx0,yy),"TETSULOG",font(GEIST,22),CYANDIM,track=6); yy+=34
    c.text((cx0,yy),"成績",font(JP,56),CREAM,bold=1); yy+=110
    # gauge card
    gh=360; b=[cx0,yy,cx1,yy+gh]; card(c,b,accent=False)
    gcx=(cx0+cx1)/2; gcy=yy+230
    gauge(c,gcx,gcy,150,0.62)
    c.text((gcx,gcy-70),"312",font(MONO,72),CYAN,anchor="ma")
    c.text((gcx,gcy+6),"TOTAL 総遭遇",font(MONO,22),CYANDIM,anchor="ma")
    yy+=gh+24
    # readouts
    reads=[("87","形式"),("4,820","乗車km"),("23","撮影地")]
    seg=(cx1-cx0-2*16)/3
    for i,(v,k) in enumerate(reads):
        bx0=cx0+ (seg+16)*i; b=[bx0,yy,bx0+seg,yy+150]; card(c,b,accent=False)
        c.text((bx0+seg/2,yy+38),v,font(MONO,46),TX,anchor="ma")
        c.text((bx0+seg/2,yy+108),k,font(JP,24),TXD,anchor="ma")
    yy+=150+24
    # monthly chart card
    chh=300; b=[cx0,yy,cx1,yy+chh]; card(c,b,accent=False)
    c.text((cx0+34,yy+26),"MONTHLY ─ 月別遭遇",font(MONO,24),CYANDIM)
    vals=[40,62,55,82,48,100,58,74,66,90,52,78]
    bw=(cx1-cx0-68)/len(vals); base=yy+chh-50; mh=160
    for i,v in enumerate(vals):
        bx=cx0+34+i*bw
        c.rrect([bx+4,base-mh*v/100,bx+bw-4,base],4,fill=CYAN)
    yy+=chh+24
    # ランキングカード
    rh=300; b=[cx0,yy,cx1,yy+rh]; card(c,b,accent=False)
    c.text((cx0+34,yy+26),"RANKING ─ よく出会う形式",font(MONO,24),CYANDIM)
    ranks=[("1","E235系  山手線","68回"),("2","E353系  あずさ","41回"),("3","EF65形  貨物","33回")]
    ry=yy+82
    for no,nm,ct in ranks:
        c.text((cx0+34,ry),no,font(MONO,30),RED)
        c.text((cx0+92,ry-2),nm,font(JP,30),TX)
        c.text((cx1-34,ry),ct,font(MONO,26),CYANDIM,anchor="ra")
        c.line([(cx0+34,ry+50),(cx1-34,ry+50)],(150,200,240,30),1)
        ry+=72
    tabbar(c,sb,3); c.save("06-stats.png")

def s_privacy(c):
    backdrop(c); header(c,"PRIVACY · PRO","データは、","あなたのものだけ。")
    sb=phone(c); statusbar(c,sb); x0,y0,x1,y1=sb
    pad=40; cx0=x0+pad; cx1=x1-pad; yy=y0+96
    c.text((cx0,yy),"設定",font(JP,56),CREAM,bold=1); yy+=104
    # Pro ticket
    th=240; b=[cx0,yy,cx1,yy+th]; ticket(c,b,edge=RED)
    c.text((cx0+40,yy+26),"特別補充券 · TETSULOG PRO",font(MONO,22),RED)
    c.text((cx0+40,yy+66),"全機能を、買い切りで",font(JP,46),CINK,bold=1)
    c.text((cx0+40,yy+128),"OCR / 順光逆光計算 / 走行音録音",font(JP,24),CINKSUB)
    c.text((cx1-34,yy+62),"980",font(SERIF,72),RED,anchor="ra")
    w980=c.tlen("980",font(SERIF,72))
    c.text((cx1-34-w980-8,yy+78),"¥",font(JP,34),RED,anchor="ra")
    c.text((cx0+40,yy+186),"下車前途無効 ・ サブスクなし ・ 買い切り",font(JP,18),(154,135,95))
    yy+=th+30
    # privacy rows
    rows=[("lock","アプリロック (Face ID)","ON"),
          ("icloud","iCloudにのみ保存","端末内"),
          ("export","JSON / CSV で書き出す","›"),
          ("shield","データを収集していません","Data Not Collected")]
    bh=110
    for icon,lab,val in rows:
        b=[cx0,yy,cx1,yy+bh]; card(c,b,accent=False)
        c.ellipse([cx0+30,yy+bh/2-20,cx0+70,yy+bh/2+20],outline=CYAN,width=3)
        c.text((cx0+96,yy+bh/2-22),lab,font(JP,30),TX)
        c.text((cx1-30,yy+bh/2-18),val,font(MONO,24),CYANDIM,anchor="ra")
        yy+=bh+18
    tabbar(c,sb,3); c.save("07-privacy.png")

SCREENS=[s_zukan,s_kiroku,s_detail,s_scan,s_map,s_stats,s_privacy]

def render_all(W,H,suffix):
    global OUT
    for fn in SCREENS:
        c=C(W,H)
        # patch save name with suffix
        orig=c.save
        fn(c)

if __name__=="__main__":
    for fn in SCREENS:
        c=C(1242,2688)
        fn(c)
    print("done 6.5inch (1242x2688)")
