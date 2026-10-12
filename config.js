// ใส่ค่าจาก Supabase: Project Settings → API (หรือ Data API)
// - supabaseUrl: Project URL เช่น https://abcdefghijk.supabase.co
// - supabaseAnonKey: คีย์ anon / public (คีย์นี้ใส่ในหน้าเว็บได้ ห้ามใส่คีย์ service_role)
// - lineProvider: เว้นว่างไว้ถ้ายังไม่ได้ตั้งค่า LINE Login ถ้าตั้งแล้วใส่ "custom:line"
// ถ้า supabaseUrl ว่าง แอพจะทำงานแบบ "ใช้ในเครื่องนี้" อย่างเดียวเหมือนเดิม
window.MIX_CONFIG = {
  supabaseUrl: 'https://supabase.com/dashboard/project/zpbxekokwyedjrbdqsad',
  supabaseAnonKey: 'sb_publishable_77zt2w6Op8Pp-151ngisMQ_3xfFq80H',
  lineProvider: ''
};
