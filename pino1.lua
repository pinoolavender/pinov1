-- Modul I/O memori virtual untuk proses internal.
--
-- File ini merupakan bagian dari paket SA MoonLoader.
-- Dilisensikan berdasarkan Lisensi MIT.
-- Hak cipta (c) 2019, Tim BlastHack <blast.hk>
--
-- Dimodifikasi oleh MonetLoader untuk dukungan Linux (sebagian)

lokal ffi = memerlukan 'ffi'
memori lokal = {} -- semua fungsi harus menerima alamat bertipe angka

akses halaman lokal = {
    TIDAK ADA AKSES = 0x00, ---
    READONLY = 0x01, -- r-- Nilai default untuk rodata.
    READWRITE = 0x03, -- rw- Default untuk bss, got, data dan lainnya.
    EKSEKUSI = 0x04, -- --x
    EXECUTE_READ = 0x05, -- rx Default untuk kode.
    EXECUTE_READWRITE = 0x07 -- rwx
}
lokal pvoid_t = ffi.typeof('void*')

ffi.cdef [[
int mprotect(void* addr, size_t len, int prot);
int memcmp(const void* ptr1, const void* ptr2, size_t num);
]]

fungsi lokal set_protection(alamat, ukuran, akses, do_print)
    alamat ia lokal = ffi.cast('uintptr_t', alamat)
    local aligned = bit.band(iaddress, 0xFFFFF000)
    local aligned_ptr = ffi.cast(pvoid_t, aligned)
    panjang lokal = bit.lshift(bit.rshift(alamat asli + ukuran - sejajar + 4095, 12), 12)
    jika ffi.C.mprotect(aligned_ptr, len, access) ~= 0 maka
        jika do_print maka
            print("memori: mprotect gagal, errno = ", ffi.errno())
        akhir
        kembalikan nilai nil
    akhir
    kembali 0
akhir

fungsi lokal unprotect(alamat, ukuran)
    local r = set_protection(address, size, page_access.EXECUTE_READWRITE, false)
    Jika r == nil maka -- Execmod tidak diizinkan.
        kembalikan set_protection(alamat, ukuran, akses_halaman.READWRITE, true)
    akhir
    kembali r
akhir

fungsi lokal unprotect_maybe(address, size, unprot)
    jika tidak terlindungi maka
        kembalikan unprotect(alamat, ukuran)
    akhir
akhir

fungsi lokal protect_maybe(alamat, ukuran, prot)
    jika prot maka
        kembalikan set_protection(alamat, ukuran, prot, true)
    akhir
akhir

fungsi memory.read(address, size, unprot)
    jika ukuran > 0 maka
        jika ukuran > 8 maka
            ukuran = 8
        akhir
        alamat = ffi.cast(pvoid_t, alamat)
        nilai lokal = ffi.new('int64_t[1]')
        local prot = unprotect_maybe(address, size, unprot)
        jika tidak unprot atau prot ~= nil maka
            ffi.copy(nilai, alamat, ukuran)
			jika ukuran <= 4 maka
				kembali ke nomor(nilai[0])
			akhir
            nilai kembalian[0]
        akhir
    akhir
akhir

fungsi memory.write(alamat, nilai, ukuran, tidak terlindungi)
    jika ukuran > 0 maka
        jika ukuran > 8 maka
            ukuran = 8
        akhir
        alamat = ffi.cast(pvoid_t, alamat)
        nilai lokal = ffi.baru('int64_t[1]', nilai)
        local prot = unprotect_maybe(address, size, unprot)
        jika tidak unprot atau prot ~= nil maka
            ffi.copy(alamat, nilai, ukuran)
        akhir
    akhir
akhir

fungsi memory.unprotect(address, size)
    alamat = ffi.cast(pvoid_t, alamat)
    kembalikan unprotect(alamat, ukuran)
akhir

fungsi memory.protect(address, size, prot)
    alamat = ffi.cast(pvoid_t, alamat)
    kembalikan set_protection(alamat, ukuran, prot, true)
akhir

fungsi memory.copy(dst, src, size, unprot)
    dst = ffi.cast(pvoid_t, dst)
    jika tipe(src) ~= 'string' maka
        src = ffi.cast(pvoid_t, src)
    akhir
    local prot = unprotect_maybe(dst, size, unprot)
    jika tidak unprot atau prot ~= nil maka
        ffi.copy(dst, src, size)
    akhir
akhir

fungsi memory.fill(address, value, size, unprot)
    alamat = ffi.cast(pvoid_t, alamat)
    local prot = unprotect_maybe(address, size, unprot)
    jika tidak unprot atau prot ~= nil maka
        ffi.isi(alamat, ukuran, nilai)
    akhir
akhir

fungsi memory.tostring(alamat, ukuran, tidak terlindungi)
    alamat = ffi.cast(pvoid_t, alamat)
    local prot = unprotect_maybe(address, size, unprot)
    jika tidak unprot atau prot ~= nil maka
        string lokal = ffi.string(alamat, ukuran)
        kembalikan string
    akhir
akhir

fungsi memory.compare(m1, m2, size)
    m1 = ffi.cast(pvoid_t, m1)
    m2 = ffi.cast(pvoid_t, m2)
    kembalikan ffi.C.memcmp(m1, m2, ukuran) == 0
akhir

fungsi memory.strptr(str)
    kembalikan ke angka(ffi.cast('uintptr_t', ffi.cast('const char*', str)))
akhir

fungsi memory.tohex(data, size, unprot)
    data = ffi.cast('const uint8_t*', data)
    local prot = unprotect_maybe(data, size, unprot)
    jika tidak unprot atau prot ~= nil maka
        string lokal = {}
        untuk i = 0, ukuran - 1 lakukan
            str[#str + 1] = bit.tohex(data[i], 2)
        akhir
        kembalikan tabel.gabungkan(str):atas()
    akhir
akhir

fungsi memory.hex2bin(hex, dst, size)
    jika #hex == 0 atau #hex % 2 ~= 0 maka
        kembalikan false
    akhir
    jika dst maka
        jika ukuran tidak sama dengan 0 maka
            kembalikan false
        akhir
        dst = ffi.cast('uint8_t*', dst)
        indeks lokal = 0
        untuk i = 1, #hex, 2 lakukan
            byte lokal = tonumber(hex:sub(i, i + 1), 16)
            jika bukan byte maka
                kembalikan false
            akhir
            dst[idx] = byte
            idx = idx + 1
            jika idx >= ukuran maka
                kembalikan nilai benar
            akhir
        akhir
        kembalikan nilai benar
    kalau tidak
        string lokal = {}
        untuk i = 1, #hex, 2 lakukan
            byte lokal = tonumber(hex:sub(i, i + 1), 16)
            jika bukan byte maka
                kembalikan nilai nil
            akhir
            str[#str + 1] = string.char(byte)
        akhir
        kembalikan tabel.gabungkan(str)
    akhir
akhir

fungsi lokal get_value(ctype, address, unprot)
    alamat = ffi.cast(pvoid_t, alamat)
    ukuran lokal = ffi.ukuran(ctype)
    local prot = unprotect_maybe(address, size, unprot)
    jika tidak unprot atau prot ~= nil maka
        nilai lokal = ffi.cast(ctype..'*', alamat)[0]
        kembalikan nilai
    akhir
akhir

fungsi lokal set_value(ctype, address, value, unprot)
    alamat = ffi.cast(pvoid_t, alamat)
    ukuran lokal = ffi.ukuran(ctype)
    local prot = unprotect_maybe(address, size, unprot)
    jika tidak unprot atau prot ~= nil maka
        ffi.cast(ctype..'*', address)[0] = nilai
    akhir
akhir

memori.dapatkan nilai = dapatkan_nilai
memory.setvalue = set_value
memory.getint8 = function(address, unprot) return get_value('int8_t', address, unprot) end
memory.getint16 = function(address, unprot) return get_value('int16_t', address, unprot) end
memory.getint32 = function(address, unprot) return get_value('int32_t', address, unprot) end
memory.getint64 = function(address, unprot) return get_value('int64_t', address, unprot) end
memory.getuint8 = function(address, unprot) return get_value('uint8_t', address, unprot) end
memory.getuint16 = function(address, unprot) return get_value('uint16_t', address, unprot) end
memory.getuint32 = function(address, unprot) return get_value('uint32_t', address, unprot) end
memory.getuint64 = function(address, unprot) return get_value('uint64_t', address, unprot) end
memory.getfloat = function(address, unprot) return get_value('float', address, unprot) end
memory.getdouble = function(address, unprot) return get_value('double', address, unprot) end
memory.setint8 = function(address, value, unprot) return set_value('int8_t', address, value, unprot) end
memory.setint16 = function(address, value, unprot) return set_value('int16_t', address, value, unprot) end
memory.setint32 = function(address, value, unprot) return set_value('int32_t', address, value, unprot) end
memory.setint64 = function(address, value, unprot) return set_value('int64_t', address, value, unprot) end
memory.setuint8 = function(address, value, unprot) return set_value('uint8_t', address, value, unprot) end
memory.setuint16 = function(address, value, unprot) return set_value('uint16_t', address, value, unprot) end
memory.setuint32 = function(address, value, unprot) return set_value('uint32_t', address, value, unprot) end
memory.setuint64 = function(address, value, unprot) return set_value('uint64_t', address, value, unprot) end
memory.setfloat = function(address, value, unprot) return set_value('float', address, value, unprot) end
memory.setdouble = function(address, value, unprot) return set_value('double', address, value, unprot) end
memory.pageaccess = page_access

kembali ke memori
