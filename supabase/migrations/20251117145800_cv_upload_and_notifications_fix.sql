-- Migration 009_cv_upload_and_notifications_fix.sql

-- BƯỚC 1: CẬP NHẬT BẢNG PROFILES ĐỂ LƯU CV URL

-- Thêm cột cv_url vào bảng profiles
ALTER TABLE public.profiles
ADD COLUMN cv_url TEXT;

-- BƯỚC 2: TẠO STORAGE BUCKET MỚI CHO TÀI LIỆU (CV)

-- Tạo storage bucket 'documents'
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', FALSE) -- Đặt là FALSE để yêu cầu Auth khi truy cập
ON CONFLICT (id) DO NOTHING;

-- BƯỚC 3: THIẾT LẬP RLS CHO BUCKET 'documents' (CVs)

-- Cho phép người dùng tải lên CV của chính họ
-- Tên file phải bắt đầu bằng UID của họ (ví dụ: 'uuid/my_cv.pdf')
CREATE POLICY "Users can upload their own CV"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Cho phép người dùng xem CV của chính họ (Yêu cầu JWT)
CREATE POLICY "Users can view their own CV"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Cho phép Quản trị viên (Admin) xem bất kỳ CV nào
CREATE POLICY "Admins can view all documents"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'documents' AND public.has_role(auth.uid(), 'admin'::app_role));

-- Cho phép người dùng cập nhật/ghi đè CV của chính họ
CREATE POLICY "Users can update their own CV"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Cho phép người dùng xóa CV của chính họ
CREATE POLICY "Users can delete their own CV"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- BƯỚC 4: CẬP NHẬT RÀNG BUỘC FK (Fix một lỗi tiềm ẩn)

-- Giả định rằng bạn đã tạo FK cho profiles.id REFERENCES auth.users.id
-- Lệnh này đảm bảo rằng cột user_id trong bảng salaries cũng có ràng buộc FK
-- (Nếu bạn đã chạy các migration trước đó, lệnh này có thể báo lỗi "already exists" - có thể bỏ qua)
-- Nếu bạn chưa thêm, thì nên thêm:
ALTER TABLE public.salaries
ADD CONSTRAINT salaries_user_id_fkey FOREIGN KEY (user_id)
REFERENCES public.profiles(id)
ON DELETE CASCADE;

-- BƯỚC 5: CẬP NHẬT CHÍNH SÁCH RLS SALARIES (Nếu cần thiết)
-- Bạn có thể thêm chính sách cho người dùng xem lương của chính họ, nếu cần.
-- CREATE POLICY "Users can view their own salaries" ON public.salaries
-- FOR SELECT USING (auth.uid() = user_id);