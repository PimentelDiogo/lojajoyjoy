// Comprime fotos numa thread separada (Web Worker), fora do alcance do
// CanvasKit do Flutter Web — evita a disputa de recursos que travava o
// navegador em alguns iPhones ao processar a foto na thread principal.
self.onmessage = async (event) => {
  const { file, maxSide } = event.data;
  // iPadOS <16.4 (e navegadores sem OffscreenCanvas) não têm como comprimir
  // aqui dentro — responde na hora em vez de deixar a Promise falhar.
  if (typeof OffscreenCanvas === 'undefined' || typeof createImageBitmap === 'undefined') {
    self.postMessage({ ok: false, error: 'OffscreenCanvas não suportado' });
    return;
  }
  try {
    const bitmap = await createImageBitmap(file);
    const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height));
    const width = Math.max(1, Math.round(bitmap.width * scale));
    const height = Math.max(1, Math.round(bitmap.height * scale));

    const canvas = new OffscreenCanvas(width, height);
    const ctx = canvas.getContext('2d');
    // Fundo branco: PNG/HEIC transparente não fica preto no JPEG.
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, width, height);
    ctx.drawImage(bitmap, 0, 0, width, height);
    bitmap.close();

    let blob = await canvas.convertToBlob({ type: 'image/webp', quality: 0.82 });
    if (!blob || blob.type !== 'image/webp') {
      blob = await canvas.convertToBlob({ type: 'image/jpeg', quality: 0.85 });
    }
    if (!blob) {
      self.postMessage({ ok: false });
      return;
    }
    const buffer = await blob.arrayBuffer();
    self.postMessage({ ok: true, buffer, contentType: blob.type }, [buffer]);
  } catch (err) {
    self.postMessage({ ok: false, error: String(err) });
  }
};
