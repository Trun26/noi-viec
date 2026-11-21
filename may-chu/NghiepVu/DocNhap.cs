using System.Text;

namespace MayChu.NghiepVu;

public static class DocNhap
{
    public static string GiaTri(string bien, string nhan)
    {
        var giaTri = Environment.GetEnvironmentVariable(bien);
        if (!string.IsNullOrWhiteSpace(giaTri))
            return giaTri;
        if (Console.IsInputRedirected)
            throw new LoiNghiepVu($"Thiếu {bien}; cần terminal tương tác để nhập.");
        Console.Write(nhan + ": ");
        return Console.ReadLine()?.Trim() ?? "";
    }

    public static string MatKhau(string bien, string nhan)
    {
        var giaTri = Environment.GetEnvironmentVariable(bien);
        if (!string.IsNullOrEmpty(giaTri))
        {
            PhienLamViec.KiemTra(giaTri.Length is >= 12 and <= 128, "Mật khẩu cần từ 12 đến 128 ký tự.");
            return giaTri;
        }
        if (Console.IsInputRedirected)
            throw new LoiNghiepVu($"Thiếu {bien}; cần terminal tương tác để nhập mật khẩu.");
        Console.Write(nhan + ": ");
        var chuoi = new StringBuilder();
        while (true)
        {
            var phim = Console.ReadKey(intercept: true);
            if (phim.Key == ConsoleKey.Enter)
            {
                Console.WriteLine();
                if (chuoi.Length is < 12 or > 128)
                {
                    Console.WriteLine("Mật khẩu cần từ 12 đến 128 ký tự. Vui lòng nhập lại.");
                    chuoi.Clear();
                    Console.Write(nhan + ": ");
                    continue;
                }
                return chuoi.ToString();
            }
            if (phim.Key == ConsoleKey.Backspace)
            {
                if (chuoi.Length > 0)
                {
                    chuoi.Length--;
                    Console.Write("\b \b");
                }
            }
            else if (!char.IsControl(phim.KeyChar))
            {
                chuoi.Append(phim.KeyChar);
                Console.Write('*');
            }
        }
    }
}
