# Lab 4 — Kiểm tra thiết kế sử dụng Testbench

Mục tiêu: làm quen với việc viết testbench bằng Verilog HDL và dùng **ModelSim-Altera**
để mô phỏng, quan sát dạng sóng, kiểm tra chức năng + timing của các thiết kế
(ALU, counter, register file, RAM) và thực hành sử dụng chip SRAM trên board DE2.

## Cấu trúc thư mục

```
lab4/
├── README.md                                  <- tài liệu này
├── Lab4_Testbench  Verification.pdf           <- đề bài
├── lab8_Verilog.pdf                           <- tham khảo Part IV (SRAM DE2)
├── Thuc hanh su dung IP cores.pdf             <- tham khảo Phần 4
├── Using_ModelSim (Q 12.1).pdf                <- hướng dẫn ModelSim
├── tut_timing_verilog.pdf                     <- timing analysis
└── src/
    ├── ex1/   alu32.v, tb_alu32.v
    ├── ex2/   counter4.v, tb_counter4_wave.v, tb_counter4_self.v
    ├── ex3/   reg_file_32x32.v, tb_reg_file_32x32.v
    ├── ex4/   dual_port_ram_1kx8.v, tb_dual_port_ram_1kx8.v
    └── ex5/   sp_ram_128x8.v, tb_sp_ram_128x8_wave.v, tb_sp_ram_128x8_self.v
```

## Cách chạy mô phỏng trong ModelSim-Altera

Ví dụ với bài 1 (tương tự cho các bài khác — thay tên file cho phù hợp):

```tcl
# Trong ModelSim transcript, chuyển về thư mục bài
cd  D:/__project_verilog/CE213/LAB_CE213/lab4/src/ex1

vlib work
vlog alu32.v tb_alu32.v
vsim -voptargs=+acc work.tb_alu32
add wave -r *
run -all
```

Bảng các testbench:

| Bài  | File DUT                  | Testbench                                             | Loại                  |
|------|---------------------------|-------------------------------------------------------|-----------------------|
| 1    | `ex1/alu32.v`             | `tb_alu32.v`                                          | self-check + `$monitor` |
| 2.1  | `ex2/counter4.v`          | `tb_counter4_wave.v`                                  | quan sát dạng sóng    |
| 2.2  | `ex2/counter4.v`          | `tb_counter4_self.v`                                  | self-checking         |
| 3    | `ex3/reg_file_32x32.v`    | `tb_reg_file_32x32.v`                                 | self-checking         |
| 4    | `ex4/dual_port_ram_1kx8.v`| `tb_dual_port_ram_1kx8.v`                             | self-checking         |
| 5.1  | `ex5/sp_ram_128x8.v`      | `tb_sp_ram_128x8_wave.v`                              | quan sát dạng sóng    |
| 5.2  | `ex5/sp_ram_128x8.v`      | `tb_sp_ram_128x8_self.v`                              | self-checking         |

Tiêu chí PASS cho các testbench self-checking: cuối log phải in dòng
`RESULT : ALL TESTS PASSED` và `fail=0` trong dòng `SUMMARY`. Mỗi tb tự dump
VCD (`.vcd`) và log (`.log`) vào cùng thư mục bài.

---

# Bài 6 — Thực hành sử dụng chip SRAM trên board DE2

Bài 6 **không có phần mô phỏng Verilog**. Sinh viên phải thực hành trên phần
cứng board DE2 (Altera): sử dụng chip SRAM có sẵn để làm bộ nhớ đọc/ghi và
kiểm tra quá trình đọc ghi trên chip. Hướng dẫn dưới đây được tổng hợp từ hai
tài liệu tham khảo nằm cùng thư mục lab4:

- `lab8_Verilog.pdf` **Part IV** — dùng trực tiếp chip SRAM ngoại vi (IS61LV25616AL-10).
- `Thuc hanh su dung IP cores.pdf` **Phần 4** — tạo khối RAM bằng MegaWizard
  Plug-in Manager (M4K block trong FPGA).

## 1. Mục tiêu

Xây dựng một bộ nhớ **32 × 8** trên DE2 bằng cách sử dụng chip SRAM ngoài
(`IS61LV25616AL-10`) thay vì M4K block bên trong FPGA, sau đó kiểm tra bằng
cách:

- Dùng các công tắc `SW` để nhập địa chỉ + dữ liệu.
- Dùng `KEY` làm xung clock và reset.
- Hiển thị địa chỉ đang chọn + dữ liệu ghi + dữ liệu đọc trên 7-seg
  `HEX7..HEX0` và `LEDG[0]` cho tín hiệu Write.

## 2. Đặc điểm phần cứng chip SRAM trên DE2

Chip `IS61LV25616AL-10` (Lab8 Part IV):

- Dung lượng: **256K × 16-bit**.
- Bus địa chỉ 18-bit `A[17:0]`.
- Bus dữ liệu **hai chiều** (inout) 16-bit `I/O[15:0]`.
- Năm tín hiệu điều khiển **tích cực thấp** (`active-low`):

| Chân  | Ý nghĩa                                                              |
|-------|----------------------------------------------------------------------|
| `/CE` | Chip Enable — phải bằng 0 trong mọi thao tác                         |
| `/OE` | Output Enable — bằng 0 khi đọc (hoặc có thể để 0 cho cả ghi/đọc)     |
| `/WE` | Write Enable — bằng 0 khi ghi                                        |
| `/UB` | Upper Byte — bằng 0 để truy cập 8-bit cao `I/O[15:8]`                |
| `/LB` | Lower Byte — bằng 0 để truy cập 8-bit thấp `I/O[7:0]`                |

**Chế độ đơn giản** được khuyến nghị trong Lab8 Part IV:
buộc cứng `CE = OE = UB = LB = 0` và chỉ điều khiển hoạt động bằng `/WE`.

## 3. Bảng pin DE2 ↔ SRAM

| Chân SRAM   | Tên pin trong DE2 Verilog top-level |
|-------------|-------------------------------------|
| `A[17:0]`   | `SRAM_ADDR[17:0]`                   |
| `I/O[15:0]` | `SRAM_DQ[15:0]`                     |
| `/CE`       | `SRAM_CE_N`                         |
| `/OE`       | `SRAM_OE_N`                         |
| `/WE`       | `SRAM_WE_N`                         |
| `/UB`       | `SRAM_UB_N`                         |
| `/LB`       | `SRAM_LB_N`                         |

Vì đặc tả bài chỉ cần 32 × 8 (5 bit địa chỉ + 8 bit dữ liệu) nên các chân
không dùng phải tie cố định trong module top-level:

- `SRAM_ADDR[17:5]` = 0 (13 bit địa chỉ cao không dùng).
- `SRAM_DQ[15:8]`   = để Z hoặc 0 (8 bit dữ liệu cao không dùng; nếu tie 0 thì
  chỉ tie khi ghi, không tie khi đọc để tránh tranh chấp bus).

## 4. Timing chính (Lab8 Part IV, Table 2)

Read cycle:

- `tAA ≤ 10 ns` — độ trễ tối đa từ khi địa chỉ ổn định đến khi data out hợp lệ.
- `tOHA ≥ 3 ns` — data out còn hợp lệ trong ít nhất 3 ns sau khi địa chỉ đổi.

Write cycle:

- `tAW ≥ 8 ns` — thời gian setup địa chỉ trước cạnh lên `/WE`.
- `tSD ≥ 6 ns` — thời gian setup data trước cạnh lên `/WE`.
- `tHA = tSA = tHD = 0` — có thể coi 0.

Ở xung clock 50 MHz (chu kỳ 20 ns) của DE2, các yêu cầu setup đều thỏa mãn
nếu ta chốt address/data trong thanh ghi ở FPGA trước khi đi ra chân.

## 5. Các bước thực hành chi tiết

### Bước 1 — Tạo project Quartus II mới

1. `File → New Project Wizard`.
2. Target chip: **Cyclone II `EP2C35F672C6`** (chip trên DE2).
3. Thêm các file Verilog: ví dụ `sram_de2_32x8.v` (top-level sẽ viết ở bước 2).

### Bước 2 — Viết Verilog top-level `sram_de2_32x8.v`

Module top-level cần khai báo đầy đủ các chân DE2 được dùng (`SW`, `KEY`,
`HEX*`, `LEDG`, cùng với nhóm `SRAM_*` phía trên). Khung tham khảo:

```verilog
module sram_de2_32x8 (
    input  wire [17:0] SW,
    input  wire [3:0]  KEY,
    output wire [6:0]  HEX7, HEX6,   // address
    output wire [6:0]  HEX5, HEX4,   // data-in
    output wire [6:0]  HEX1, HEX0,   // data-out
    output wire [0:0]  LEDG,         // LEDG[0] = Write signal
    // SRAM interface
    output wire [17:0] SRAM_ADDR,
    inout  wire [15:0] SRAM_DQ,
    output wire        SRAM_CE_N,
    output wire        SRAM_OE_N,
    output wire        SRAM_WE_N,
    output wire        SRAM_UB_N,
    output wire        SRAM_LB_N
);

    // --- Ánh xạ user I/O ---
    wire [4:0] addr     = SW[15:11];      // 5-bit address (chọn 32 ô)
    wire [7:0] data_in  = SW[7:0];        // 8-bit data-in
    wire       write_en = SW[17];         // 1 = Write, 0 = Read
    wire       clock    = KEY[0];         // KEY là active-low push-button

    // --- Cố định 4 tín hiệu điều khiển ---
    assign SRAM_CE_N = 1'b0;
    assign SRAM_OE_N = 1'b0;
    assign SRAM_UB_N = 1'b0;              // dùng cả upper + lower byte
    assign SRAM_LB_N = 1'b0;

    // --- /WE = 0 khi muốn ghi (Write=1 -> /WE=0) ---
    assign SRAM_WE_N = ~write_en;

    // --- Tie 13 bit địa chỉ cao về 0 ---
    assign SRAM_ADDR = {13'b0, addr};

    // --- Xử lý bus inout: chỉ drive khi đang ghi ---
    assign SRAM_DQ = write_en ? {8'b0, data_in} : 16'bz;

    // --- Data đọc về: 8 bit thấp ---
    wire [7:0] data_out = SRAM_DQ[7:0];

    // --- LEDG[0] = tín hiệu Write để quan sát trên board ---
    assign LEDG[0] = write_en;

    // --- Module hex_to_7seg (tự viết hoặc tái sử dụng từ lab trước) ---
    hex_to_7seg u_h7 (.hex(1'b0),             .seg(HEX7));  // hex cao của addr = 0
    hex_to_7seg u_h6 (.hex({1'b0, addr[4:1]}),.seg(HEX6));  // hex thấp của addr
    hex_to_7seg u_h5 (.hex(data_in[7:4]),     .seg(HEX5));
    hex_to_7seg u_h4 (.hex(data_in[3:0]),     .seg(HEX4));
    hex_to_7seg u_h1 (.hex(data_out[7:4]),    .seg(HEX1));
    hex_to_7seg u_h0 (.hex(data_out[3:0]),    .seg(HEX0));

endmodule
```

> Lưu ý: `hex_to_7seg` là module bộ giải mã 4-bit → 7-segment active-low (7 bit),
> sinh viên tự viết hoặc dùng lại từ các lab trước. Module không in ở đây
> để giữ README ngắn gọn.

### Bước 3 — Pin Assignment

Có hai cách:

- **Cách nhanh**: import file `DE2_pin_assignments.qsf` do Altera cung cấp
  (`Assignments → Import Assignments`), file này đã gán sẵn tất cả các chân
  `SW`, `KEY`, `HEX*`, `LEDG`, và đặc biệt cả các chân `SRAM_*`.
- **Cách thủ công**: mở `Assignments → Pin Planner` và gán từng tên pin theo
  DE2 User Manual (phần 4.4 "Using the SRAM/SSRAM/SDRAM").

### Bước 4 — Biên dịch & nạp xuống board

1. `Processing → Start Compilation` (Ctrl+L).
2. Kiểm tra Compilation Report không có error/warning nghiêm trọng.
3. Kết nối DE2 qua USB-Blaster, chọn `Programmer → Hardware Setup → USB-Blaster`.
4. Nạp `.sof` xuống chip (chọn mode JTAG).

### Bước 5 — Kiểm thử trên board

1. Đặt `SW[17] = 1` (Write).
2. Chỉnh `SW[15:11]` để chọn địa chỉ (0..31), `SW[7:0]` để chọn data-in.
3. Nhấn `KEY[0]` (cạnh lên sau khi nhả) — mỗi lần nhấn sẽ ghi 1 byte.
4. Đặt `SW[17] = 0` (Read).
5. Thay `SW[15:11]` → `HEX1,HEX0` sẽ hiển thị giá trị đã ghi trước đó tại địa chỉ đó.
6. **Kiểm tra tất cả 32 ô nhớ**: lặp lại bước 2–5 với 32 địa chỉ khác nhau;
   data đọc về phải trùng data đã ghi.

## 6. Cách thay thế — Dùng IP core Memory Compiler (M4K)

Tài liệu `Thuc hanh su dung IP cores.pdf` Phần 4 mô tả cách tạo khối RAM
trong nội bộ FPGA bằng **MegaWizard Plug-in Manager**. Cách này được giới
thiệu để so sánh với SRAM ngoài và làm tham khảo cho các bài khác (bài 4,
bài 5 cũng có thể sinh RAM bằng IP core).

Các bước:

1. `Tools → MegaWizard Plug-in Manager → Create a new custom megafunction`.
2. Chọn `Memory Compiler → RAM: 1-PORT`, ngôn ngữ **Verilog HDL**, tên
   output `ramlpm.v`.
3. Trang "Widths/Blk Type/Clks": đặt size **32 words × 8 bits**, block type
   **M4K**, clock mode **Single clock**.
4. Trang "Regs/Clken/Byte Enable/Aclrs": ở mục *Which ports should be registered?*
   **bỏ chọn (deselect)** `'q' output port` để có async read khớp với sơ đồ
   Figure 1b của Lab8 (tức output không qua register).
5. Trang *Mem Init* (tuỳ chọn): có thể chỉ định file `ramlpm.mif` để khởi tạo
   nội dung. File `.mif` do sinh viên tự tạo (`File → New → Memory Initialization File`).
6. Nhấn *Finish* để Quartus sinh `ramlpm.v`.
7. Trong top-level Verilog, instantiate `ramlpm` thay cho phần inout SRAM:

   ```verilog
   ramlpm u_ram (
       .address (addr),
       .clock   (clock),
       .data    (data_in),
       .wren    (write_en),
       .q       (data_out)
   );
   ```

8. (Tuỳ chọn) Bật **In-System Memory Content Editor**: trên trang cuối của
   wizard tick `Allow In-System Memory Content Editor to capture and update
   content independently of the system clock`, và đặt `Instance ID` (ví dụ
   `32x8`). Sau khi nạp xuống board, dùng `Tools → In-System Memory Content
   Editor` để xem/ghi nội dung RAM qua JTAG mà không cần SW/KEY.
9. Trước khi biên dịch, vào `Assignments → Settings → Analysis & Synthesis
   Settings → Default Parameters`, thêm tham số `CYCLONEII_SAFE_WRITE` với
   giá trị `RESTRUCTURE` để cho phép In-System Memory Content Editor ghi
   được nội dung.

## 7. Check-list nộp bài

- [ ] Project Quartus II compile thành công, target chip `EP2C35F672C6`.
- [ ] File top-level Verilog (ví dụ `sram_de2_32x8.v`) có cổng `inout SRAM_DQ`
      được xử lý tri-state đúng (chỉ drive khi ghi).
- [ ] Pin assignment đúng với DE2 User Manual (hoặc import từ `DE2_pin_assignments.qsf`).
- [ ] Demo trên board DE2: ghi/đọc thành công **đủ 32 ô nhớ**, data đọc khớp
      data ghi.
- [ ] Screenshot / ảnh chụp board hiển thị một vài cặp (address, data ghi, data đọc).
- [ ] Báo cáo ngắn nhận xét khác biệt khi dùng **chip SRAM ngoài** so với
      **M4K block** (timing, dung lượng, cách xử lý bus inout).

## 8. Tài liệu tham khảo

- `lab4/lab8_Verilog.pdf` — Part IV (Laboratory Exercise 8, Altera University Program).
- `lab4/Thuc hanh su dung IP cores.pdf` — Phần 4 (Memory Compiler / IP core).
- DE2 User Manual — Section 4.4 "Using the SRAM/SSRAM/SDRAM".
- Datasheet ISSI `IS61LV25616AL` — chi tiết timing và các mode khác.
