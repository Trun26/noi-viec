param([string]$DiaChi='http://127.0.0.1:5080/api/v1')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Net.Http
$http=[System.Net.Http.HttpClient]::new()
function Goi($Cach,$DuongDan,$DuLieu=$null,$Token='',$Ma=200) {
  $r=[System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Cach),"$DiaChi/$DuongDan")
  if($Token){$r.Headers.Authorization=[System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer',$Token)}
  if($null -ne $DuLieu){$r.Content=[System.Net.Http.StringContent]::new(($DuLieu|ConvertTo-Json -Depth 10),[Text.Encoding]::UTF8,'application/json')}
  $s=$null
  try {
    $s=$http.SendAsync($r).GetAwaiter().GetResult()
    $text=$s.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if([int]$s.StatusCode -ne $Ma){throw "$Cach $DuongDan : $([int]$s.StatusCode), mong đợi $Ma. $text"}
    if($text){$text|ConvertFrom-Json}
  } finally {if($s){$s.Dispose()};$r.Dispose()}
}
$id=$null;$token=''
try {
  $email=Read-Host 'Email quản trị'
  $mk=Read-Host 'Mật khẩu quản trị' -AsSecureString
  $vao=Goi POST 'tai-khoan/dang-nhap' @{email=$email;matKhau=([Net.NetworkCredential]::new('',$mk).Password)}
  $token=$vao.maTruyCap
  Goi GET 'quan-tri/tong-quan' $null '' 401 | Out-Null
  $tong=Goi GET 'quan-tri/tong-quan' $null $token
  if(@($tong.doanhThu).Count -ne 6){throw 'Biểu đồ phải có đủ sáu tháng.'}
  $ma=[guid]::NewGuid().ToString('N')
  $matKhau="KiemThu!$ma"
  $d=@{email="qt-$ma@example.invalid";hoTen='Kiểm thử quản trị';loai='UngVien';vaiTro='ThanhVien';biKhoa=$false;doanhNghiepId=$null;matKhau=$matKhau}
  $moi=Goi POST 'quan-tri/nguoi-dung' $d $token
  $id=$moi.id
  $tv=(Goi POST 'tai-khoan/dang-nhap' @{email=$d.email;matKhau=$matKhau}).maTruyCap
  Goi GET 'quan-tri/tong-quan' $null $tv 403 | Out-Null
  Goi DELETE "quan-tri/nguoi-dung/$id" $null $tv 403 | Out-Null
  $ds=Goi GET "quan-tri/nguoi-dung?nhom=UngVien&q=$ma" $null $token
  if(@($ds.duLieu|Where-Object id -eq $id).Count -ne 1){throw 'Không tìm thấy ứng viên vừa tạo.'}
  $d.hoTen='Đã sửa tên';$d.matKhau=''
  Goi PUT "quan-tri/nguoi-dung/$id" $d $token | Out-Null
  Goi GET 'tai-khoan/toi' $null $tv 401 | Out-Null
  $d.loai='NhaTuyenDung'
  Goi PUT "quan-tri/nguoi-dung/$id" $d $token | Out-Null
  $ds=Goi GET "quan-tri/nguoi-dung?nhom=ChuaGan&q=$ma" $null $token
  if(@($ds.duLieu|Where-Object id -eq $id).Count -ne 1){throw 'Phân loại nhà tuyển dụng chưa gắn doanh nghiệp không đúng.'}
  $d.biKhoa=$true
  Goi PUT "quan-tri/nguoi-dung/$id" $d $token | Out-Null
  Goi POST 'tai-khoan/dang-nhap' @{email=$d.email;matKhau=$matKhau} '' 401 | Out-Null
  Goi DELETE "quan-tri/nguoi-dung/$($vao.taiKhoan.id)" $null $token 400 | Out-Null
  Goi DELETE "quan-tri/nguoi-dung/$id" $null $token | Out-Null
  $id=$null
  Write-Output 'Đạt: quyền quản trị, sáu tháng doanh thu, thêm/tìm/sửa/phân loại/khóa/xóa tài khoản, thu hồi phiên và chặn tự xóa.'
} finally {
  if($id -and $token){Goi DELETE "quan-tri/nguoi-dung/$id" $null $token | Out-Null}
  $http.Dispose()
}
