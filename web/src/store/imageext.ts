export let imageext = 'webp';

export function setImageExtension(ext: string) {
  if (ext && ext !== '') imageext = ext;
}
