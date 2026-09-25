<?php

namespace App\Http\Controllers\Api;

use App\Models\Siswa;
use App\Models\Kelas;
use Illuminate\Http\Request;

class SiswaController extends BaseApiController
{
    public function index(Request $request)
    {
        $query = Siswa::with('kelas');

        if ($request->filled('kelas_id')) {
            $query->where('kelas_id', $request->kelas_id);
        }

        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->where('nama', 'like', "%{$search}%")
                  ->orWhere('nis', 'like', "%{$search}%")
                  ->orWhere('nisn', 'like', "%{$search}%");
            });
        }

        $siswa = $query->orderBy('nama', 'asc')->get();

        return $this->sendResponse($siswa, 'Daftar data siswa');
    }

    public function show($id)
    {
        $siswa = Siswa::with('kelas')->find($id);

        if (!$siswa) {
            return $this->sendError('Data siswa tidak ditemukan', [], 404);
        }

        return $this->sendResponse($siswa, 'Detail data siswa');
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data siswa.', [], 403);
        }

        $validated = $request->validate([
            'nis' => 'required|string|max:20|unique:siswa,nis',
            'nisn' => 'required|string|max:20|unique:siswa,nisn',
            'nama' => 'required|string|max:255',
            'kelas_id' => 'required|exists:kelas,id',
        ]);

        $siswa = Siswa::create([
            'nis' => trim($validated['nis']),
            'nisn' => trim($validated['nisn']),
            'nama' => trim($validated['nama']),
            'kelas_id' => $validated['kelas_id'],
        ]);

        $siswa->load('kelas');

        return $this->sendResponse($siswa, 'Data siswa berhasil ditambahkan', 201);
    }

    public function update(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data siswa.', [], 403);
        }

        $siswa = Siswa::find($id);

        if (!$siswa) {
            return $this->sendError('Data siswa tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'nis' => 'sometimes|required|string|max:20|unique:siswa,nis,' . $id,
            'nisn' => 'sometimes|required|string|max:20|unique:siswa,nisn,' . $id,
            'nama' => 'sometimes|required|string|max:255',
            'kelas_id' => 'sometimes|required|exists:kelas,id',
        ]);

        $data = [];
        if (isset($validated['nis'])) $data['nis'] = trim($validated['nis']);
        if (isset($validated['nisn'])) $data['nisn'] = trim($validated['nisn']);
        if (isset($validated['nama'])) $data['nama'] = trim($validated['nama']);
        if (isset($validated['kelas_id'])) $data['kelas_id'] = $validated['kelas_id'];

        $siswa->update($data);
        $siswa->load('kelas');

        return $this->sendResponse($siswa, 'Data siswa berhasil diperbarui');
    }

    public function destroy(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data siswa.', [], 403);
        }

        $siswa = Siswa::find($id);

        if (!$siswa) {
            return $this->sendError('Data siswa tidak ditemukan', [], 404);
        }

        $siswa->delete();

        return $this->sendResponse(null, 'Data siswa berhasil dihapus');
    }

    public function template(Request $request)
    {
        $format = strtolower($request->query('format', ''));

        if ($format === 'xlsx' || $format === 'excel' || $request->is('*excel*')) {
            $tempFile = tempnam(sys_get_temp_dir(), 'gurita_tpl_') . '.xlsx';
            $this->generateXlsxTemplate($tempFile);

            $headers = [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Content-Disposition' => 'attachment; filename="template_import_siswa.xlsx"',
            ];

            return response()->download($tempFile, 'template_import_siswa.xlsx', $headers)->deleteFileAfterSend(true);
        }

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="template_import_siswa.csv"',
        ];

        $content = "nis,nisn,nama\n241031,0088001031,I Made Pratama Jaya\n241032,0088001032,Ni Putu Sintya Dewi\n241033,0088001033,I Komang Agus Setiawan\n241034,0088001034,Kadek Dwi Lestari\n241035,0088001035,I Ketut Surya Dharma\n";

        return response($content, 200, $headers);
    }

    public function import(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengimpor data siswa.', [], 403);
        }

        $request->validate([
            'kelas_id' => 'required|exists:kelas,id',
        ]);

        $kelas = Kelas::find($request->kelas_id);
        $imported = [];
        $skipped = [];

        // Mode 1: Array payload (parsed from client or direct JSON)
        if ($request->has('students') && is_array($request->students)) {
            foreach ($request->students as $row) {
                $nis = isset($row['nis']) ? trim((string)$row['nis']) : '';
                $nisn = isset($row['nisn']) ? trim((string)$row['nisn']) : '';
                $nama = isset($row['nama']) ? trim((string)$row['nama']) : '';

                if (empty($nis) || empty($nisn) || empty($nama)) {
                    $skipped[] = ['row' => $row, 'reason' => 'Kolom tidak lengkap'];
                    continue;
                }

                $exists = Siswa::where('nis', $nis)->orWhere('nisn', $nisn)->first();
                if ($exists) {
                    $skipped[] = ['row' => $row, 'reason' => 'NIS atau NISN sudah terdaftar'];
                    continue;
                }

                $s = Siswa::create([
                    'nis' => $nis,
                    'nisn' => $nisn,
                    'nama' => $nama,
                    'kelas_id' => $kelas->id,
                ]);
                $imported[] = $s;
            }
        } elseif ($request->hasFile('file')) {
            // Mode 2: Uploaded CSV/Excel file
            $file = $request->file('file');
            $extension = strtolower($file->getClientOriginalExtension());

            if ($extension === 'xlsx') {
                $rows = $this->parseXlsxFile($file->getRealPath());
                $header = true;
                foreach ($rows as $data) {
                    if ($header) {
                        $header = false;
                        $first = strtolower(implode(' ', $data));
                        if (str_contains($first, 'nis') || str_contains($first, 'nama')) {
                            continue;
                        }
                    }

                    if (count($data) >= 3) {
                        $nis = trim($data[0]);
                        $nisn = trim($data[1]);
                        $nama = trim($data[2]);

                        if (empty($nis) || empty($nisn) || empty($nama)) {
                            continue;
                        }

                        $exists = Siswa::where('nis', $nis)->orWhere('nisn', $nisn)->first();
                        if ($exists) {
                            $skipped[] = ['nis' => $nis, 'reason' => 'Sudah terdaftar'];
                            continue;
                        }

                        $s = Siswa::create([
                            'nis' => $nis,
                            'nisn' => $nisn,
                            'nama' => $nama,
                            'kelas_id' => $kelas->id,
                        ]);
                        $imported[] = $s;
                    }
                }
            } else {
                $handle = fopen($file->getRealPath(), 'r');
                $header = true;

                while (($data = fgetcsv($handle, 1000, ',')) !== false) {
                    if (count($data) == 1 && strpos($data[0], ';') !== false) {
                        $data = explode(';', $data[0]);
                    }

                    if ($header) {
                        $header = false;
                        continue;
                    }

                    if (count($data) >= 3) {
                        $nis = trim($data[0]);
                        $nisn = trim($data[1]);
                        $nama = trim($data[2]);

                        if (empty($nis) || empty($nisn) || empty($nama)) {
                            continue;
                        }

                        $exists = Siswa::where('nis', $nis)->orWhere('nisn', $nisn)->first();
                        if ($exists) {
                            $skipped[] = ['nis' => $nis, 'reason' => 'Sudah terdaftar'];
                            continue;
                        }

                        $s = Siswa::create([
                            'nis' => $nis,
                            'nisn' => $nisn,
                            'nama' => $nama,
                            'kelas_id' => $kelas->id,
                        ]);
                        $imported[] = $s;
                    }
                }
                fclose($handle);
            }
        } else {
            return $this->sendError('Data siswa atau file import wajib disertakan.', [], 422);
        }

        return $this->sendResponse([
            'imported_count' => count($imported),
            'skipped_count' => count($skipped),
            'kelas' => $kelas->nama_kelas,
        ], 'Import data siswa berhasil. ' . count($imported) . ' siswa ditambahkan.');
    }

    private function generateXlsxTemplate($outputPath)
    {
        $zip = new \ZipArchive();
        if ($zip->open($outputPath, \ZipArchive::CREATE | \ZipArchive::OVERWRITE) !== true) {
            return false;
        }

        $contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>';

        $rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>';

        $wbRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>';

        $workbook = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Data Siswa" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>';

        $styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font><name val="Calibri"/><sz val="11"/></font>
    <font><b/><color rgb="FFFFFFFF"/><name val="Calibri"/><sz val="11"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF2563EB"/></patternFill></fill>
  </fills>
  <borders count="2">
    <border><left/><right/><top/><bottom/><diagonal/></border>
    <border>
      <left style="thin"><color rgb="FFD1D5DB"/></left>
      <right style="thin"><color rgb="FFD1D5DB"/></right>
      <top style="thin"><color rgb="FFD1D5DB"/></top>
      <bottom style="thin"><color rgb="FFD1D5DB"/></bottom>
    </border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/>
  </cellXfs>
</styleSheet>';

        $sheet1 = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <cols>
    <col min="1" max="1" width="16" customWidth="1"/>
    <col min="2" max="2" width="20" customWidth="1"/>
    <col min="3" max="3" width="35" customWidth="1"/>
  </cols>
  <sheetData>
    <row r="1" ht="24" customHeight="1">
      <c r="A1" t="inlineStr" s="1"><is><t>nis</t></is></c>
      <c r="B1" t="inlineStr" s="1"><is><t>nisn</t></is></c>
      <c r="C1" t="inlineStr" s="1"><is><t>nama</t></is></c>
    </row>
    <row r="2">
      <c r="A2" t="inlineStr" s="2"><is><t>241031</t></is></c>
      <c r="B2" t="inlineStr" s="2"><is><t>0088001031</t></is></c>
      <c r="C2" t="inlineStr" s="2"><is><t>I Made Pratama Jaya</t></is></c>
    </row>
    <row r="3">
      <c r="A3" t="inlineStr" s="2"><is><t>241032</t></is></c>
      <c r="B3" t="inlineStr" s="2"><is><t>0088001032</t></is></c>
      <c r="C3" t="inlineStr" s="2"><is><t>Ni Putu Sintya Dewi</t></is></c>
    </row>
    <row r="4">
      <c r="A4" t="inlineStr" s="2"><is><t>241033</t></is></c>
      <c r="B4" t="inlineStr" s="2"><is><t>0088001033</t></is></c>
      <c r="C4" t="inlineStr" s="2"><is><t>I Komang Agus Setiawan</t></is></c>
    </row>
    <row r="5">
      <c r="A5" t="inlineStr" s="2"><is><t>241034</t></is></c>
      <c r="B5" t="inlineStr" s="2"><is><t>0088001034</t></is></c>
      <c r="C5" t="inlineStr" s="2"><is><t>Kadek Dwi Lestari</t></is></c>
    </row>
    <row r="6">
      <c r="A6" t="inlineStr" s="2"><is><t>241035</t></is></c>
      <c r="B6" t="inlineStr" s="2"><is><t>0088001035</t></is></c>
      <c r="C6" t="inlineStr" s="2"><is><t>I Ketut Surya Dharma</t></is></c>
    </row>
  </sheetData>
</worksheet>';

        $zip->addFromString('[Content_Types].xml', $contentTypes);
        $zip->addFromString('_rels/.rels', $rels);
        $zip->addFromString('xl/_rels/workbook.xml.rels', $wbRels);
        $zip->addFromString('xl/workbook.xml', $workbook);
        $zip->addFromString('xl/styles.xml', $styles);
        $zip->addFromString('xl/worksheets/sheet1.xml', $sheet1);

        $zip->close();
        return true;
    }

    private function parseXlsxFile($filePath)
    {
        $zip = new \ZipArchive();
        if ($zip->open($filePath) !== true) {
            return [];
        }

        $sharedStrings = [];
        if (($index = $zip->locateName('xl/sharedStrings.xml')) !== false) {
            $xml = @simplexml_load_string($zip->getFromIndex($index));
            if ($xml && isset($xml->si)) {
                foreach ($xml->si as $val) {
                    $sharedStrings[] = (string)($val->t ?? ($val->r ? implode('', (array)$val->r->t) : ''));
                }
            }
        }

        $rows = [];
        if (($sheetIndex = $zip->locateName('xl/worksheets/sheet1.xml')) !== false) {
            $sheetXml = @simplexml_load_string($zip->getFromIndex($sheetIndex));
            if ($sheetXml && isset($sheetXml->sheetData->row)) {
                foreach ($sheetXml->sheetData->row as $row) {
                    $rowData = [];
                    foreach ($row->c as $cell) {
                        $attr = $cell->attributes();
                        $type = (string)($attr['t'] ?? '');
                        $val = '';
                        if ($type === 's') {
                            $idx = (int)$cell->v;
                            $val = $sharedStrings[$idx] ?? '';
                        } elseif ($type === 'inlineStr') {
                            $val = (string)($cell->is->t ?? '');
                        } else {
                            $val = (string)($cell->v ?? '');
                        }
                        $rowData[] = trim($val);
                    }
                    if (!empty(array_filter($rowData))) {
                        $rows[] = $rowData;
                    }
                }
            }
        }
        $zip->close();
        return $rows;
    }
}
