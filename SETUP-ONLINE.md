# ตั้งค่าก๊วนออนไลน์ (Supabase + Vercel)

ทำครั้งเดียว ใช้เวลาประมาณ 20–30 นาที หลังตั้งค่าเสร็จ แอพจะทำงานแบบนี้:

- **ผู้จัด** เข้าสู่ระบบด้วย Google (หรืออีเมล) สร้างก๊วนได้หลายก๊วน แต่ละก๊วนแยกข้อมูลกันชัดเจน
- **สมาชิก** แค่กดลิงก์ที่ผู้จัดแชร์ หรือใส่รหัสก๊วน 8 ตัว ก็เห็นคู่ คะแนน อันดับ และยอดเงินแบบเรียลไทม์ โดยไม่ต้องสมัคร
- ปุ่ม **"เริ่มใช้งานทันที"** แบบเดิมยังใช้ได้ สำหรับคนที่ไม่อยากล็อกอิน

---

## ขั้นที่ 1: สร้างโปรเจกต์ Supabase

1. สมัครที่ [supabase.com](https://supabase.com) แล้วกด **New project**
2. ตั้งชื่อ เช่น `badminton-mixmatch` ตั้งรหัสผ่านฐานข้อมูล แล้วเลือก Region ใกล้ไทยที่สุด เช่น Singapore
3. รอสร้างเสร็จประมาณ 1–2 นาที

## ขั้นที่ 2: สร้างตาราง

1. ในเมนูซ้าย เลือก **SQL Editor** แล้วกด **New query**
2. เปิดไฟล์ `supabase-schema.sql` คัดลอกทั้งหมดไปวาง แล้วกด **Run**
3. ต้องขึ้นว่า Success

## ขั้นที่ 3: ใส่คีย์ลงในแอพ

1. ไปที่ **Project Settings → API Keys** (บางเวอร์ชันชื่อ **API**)
2. คัดลอก **Project URL** และคีย์ **anon public** หรือ **publishable**
3. เปิดไฟล์ `config.js` แล้วใส่ค่า:

```js
window.MIX_CONFIG = {
  supabaseUrl: 'https://xxxxxxxx.supabase.co',
  supabaseAnonKey: 'คีย์ anon หรือ publishable',
  lineProvider: ''
};
```

**ห้ามใช้คีย์ `service_role` หรือ `secret` เด็ดขาด** เพราะเป็นคีย์ที่ข้ามสิทธิ์ทุกอย่าง ส่วนคีย์ anon และ publishable ออกแบบมาให้อยู่ในหน้าเว็บได้ ข้อมูลยังปลอดภัยด้วยกฎสิทธิ์ที่สร้างในขั้นที่ 2

## ขั้นที่ 4: Deploy ขึ้น Vercel

ทำตามวิธีเดิม: อัปโหลดไฟล์ทั้งหมดในโฟลเดอร์นี้ขึ้น GitHub แล้ว Import ใน Vercel (ถ้าเคย deploy แล้ว ให้อัปโหลดไฟล์ใหม่ทับ)

จดลิงก์ที่ได้ไว้ เช่น `https://badminton-mixmatch.vercel.app`

## ขั้นที่ 5: ตั้งค่าลิงก์ใน Supabase

ไปที่ **Authentication → URL Configuration**

- **Site URL:** ใส่ลิงก์ Vercel ของคุณ
- **Redirect URLs:** กด Add URL แล้วใส่ลิงก์ Vercel ต่อท้ายด้วย `/**` เช่น `https://badminton-mixmatch.vercel.app/**`

ถึงขั้นนี้ **ล็อกอินด้วยอีเมลใช้ได้แล้ว** ระบบส่งอีเมลเริ่มต้นของ Supabase ส่งได้จำนวนจำกัดต่อชั่วโมง เพียงพอสำหรับผู้จัดไม่กี่คน

## ขั้นที่ 6: เปิดล็อกอินด้วย Google

**ฝั่ง Google**
1. เข้า [Google Cloud Console](https://console.cloud.google.com) แล้วสร้างโปรเจกต์ใหม่
2. ไปที่ **APIs & Services → OAuth consent screen**
   - เลือก External
   - ใส่ชื่อแอพ "Badminton Mix&Match" และอีเมลติดต่อ
   - Publish ให้เป็น In production เพื่อให้ใครก็ล็อกอินได้
3. ไปที่ **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   - Application type: **Web application**
   - Authorized redirect URIs: ใส่ Callback URL ที่คัดลอกจากหน้า Google ใน Supabase (ข้อถัดไป) หน้าตาประมาณ `https://xxxxxxxx.supabase.co/auth/v1/callback`
4. คัดลอก **Client ID** และ **Client Secret**

**ฝั่ง Supabase**
1. ไปที่ **Authentication → Sign In / Providers → Google**
2. เปิดใช้งาน ใส่ Client ID และ Client Secret แล้วกด Save

## ขั้นที่ 7 (ไม่บังคับ): ล็อกอินด้วย LINE

Supabase ไม่มีปุ่ม LINE ให้ตรง ๆ แต่เพิ่มเองได้ผ่าน "Custom OIDC provider" แพ็กเกจฟรีเพิ่มได้สูงสุด 3 ตัว ([Supabase Docs](https://supabase.com/docs/guides/auth/custom-oauth-providers)) ขั้นนี้ผมยังไม่ได้ทดสอบกับบัญชีจริง ถ้าติดตรงไหนส่ง error มาได้เลย

1. ที่ [LINE Developers Console](https://developers.line.biz/console/) สร้าง Provider แล้วสร้างช่องทางแบบ **LINE Login**
2. ในแท็บ OpenID Connect ขอสิทธิ์ **Email address permission** ระบบนี้ต้องใช้อีเมลของผู้จัด
3. ใน Supabase ไปที่ **Authentication → Sign In / Providers → New Provider → Auto-discovery (OIDC)** แล้วใส่:
   - Identifier: `custom:line`
   - Client ID: Channel ID ของ LINE
   - Client Secret: Channel secret
   - Issuer URL: `https://access.line.me`
4. คัดลอก Callback URL จากฟอร์มนั้น ไปใส่ใน LINE Login → **Callback URL**
5. ใน `config.js` ใส่ `lineProvider: 'custom:line'` แล้ว deploy ใหม่ ปุ่ม "เข้าสู่ระบบด้วย LINE" จะขึ้นมาเอง

---

## อัปเดต: ลิงก์กรรมการนับแต้มสด (ต้องทำครั้งเดียว)

ถ้าเคยตั้งค่าไว้ก่อนเดือนตุลาคม 2569 ต้องอัปเดตฐานข้อมูลก่อน ปุ่ม "ลิงก์กรรมการ" ถึงจะใช้ได้

1. เปิด Supabase → **SQL Editor** → **New query**
2. คัดลอกไฟล์ `supabase-schema.sql` ทั้งไฟล์ (เวอร์ชันใหม่) ไปวาง แล้วกด **Run**
3. ต้องขึ้นว่า Success รันซ้ำได้ ข้อมูลก๊วนเดิมไม่หาย

สิ่งที่เพิ่ม:
- คอลัมน์ `ref_token` ในตาราง groups สำหรับเก็บรหัสลิงก์กรรมการ
- ตาราง `live_scores` สำหรับเก็บคะแนนสด
- ฟังก์ชัน `ref_check`, `ref_put`, `get_live`: ให้กรรมการที่มีลิงก์ส่งคะแนนได้อย่างเดียว แก้ข้อมูลอื่นของก๊วนไม่ได้

ถ้าลิงก์หลุดไปถึงคนที่ไม่ควรได้ ผู้จัดกด "ลิงก์กรรมการ" → "เปลี่ยนลิงก์ใหม่" ลิงก์เดิมจะใช้ไม่ได้ทันที

## ทดสอบ

1. เปิดลิงก์ Vercel แล้วกด **เข้าสู่ระบบด้วย Google**
2. สร้างก๊วน แล้วเพิ่มผู้เล่น 4 คน
3. กด **แชร์ลิงก์ให้ก๊วน** แล้วเปิดลิงก์นั้นบนมือถืออีกเครื่อง หรือในหน้าต่างไม่ระบุตัวตน
4. ในเครื่องผู้จัด กดจัดรอบและใส่คะแนน
5. อีกเครื่องควรเห็นคู่และคะแนนอัปเดตภายในไม่กี่วินาที ถ้าการแจ้งเตือนเรียลไทม์ไม่ทำงาน แอพจะดึงข้อมูลใหม่ทุก 20 วินาทีอยู่แล้ว

## ข้อควรรู้

- **ใครแก้ไขได้:** ผู้จัดที่สร้างก๊วนเท่านั้น
- **ใครดูได้:** ทุกคนที่มีรหัสหรือลิงก์ รวมถึงช่องทางชำระเงินด้วย อย่าแชร์ลิงก์ในที่สาธารณะ
- **รหัสก๊วนเดาได้ยาก:** รหัส 8 ตัวสุ่ม และไม่มีใครดูรายชื่อก๊วนทั้งหมดได้
- **ไม่มีเน็ตในสนาม:** ผู้จัดใช้ต่อได้ ระบบจะบันทึกขึ้นออนไลน์เองเมื่อกลับมามีเน็ต ป้ายสถานะข้างชื่อก๊วนจะบอกว่าบันทึกแล้วหรือยัง
- **ผู้จัดใช้ 2 เครื่องพร้อมกัน:** ถ้าแก้พร้อมกัน ระบบจะเก็บการแก้ครั้งล่าสุด
- **อัปเดตเวอร์ชัน:** ทุกครั้งที่ deploy ใหม่ ให้เปลี่ยนเลขในบรรทัด `VERSION` ของ `sw.js`
