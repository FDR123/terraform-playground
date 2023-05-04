const fs = require('fs');
const archiver = require('archiver');

const output = fs.createWriteStream('package.zip');
const archive = archiver('zip', {
  zlib: { level: 9 }, // Sets the compression level.
});

output.on('close', () => {
  console.log(`Created package.zip with a total size of ${archive.pointer()} bytes`);
});

archive.on('warning', (err) => {
  if (err.code === 'ENOENT') {
    console.warn(err);
  } else {
    throw err;
  }
});

archive.on('error', (err) => {
  throw err;
});

archive.pipe(output);

// Add all files and folders in the current directory
archive.glob('**/*', {
  dot: true,
  ignore: ['*.zip', '*.git*', 'node_modules/archiver/**'],
});

archive.finalize();
