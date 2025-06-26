export let imagepath = 'https://i.fmfile.com/crYy4c7aRNeXoSSaCocBd';

export function setImagePath(path: string) {
  if (path && path !== '') imagepath = path;
}
