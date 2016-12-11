BigPack = require "."
Promise = require "bluebird"
path = require "path"
fs = require "fs"
rename = Promise.promisify fs.rename
pack = BigPack()
moveTo = (targetDir) -> (srcFile) -> 
  rename srcFile, path.join targetDir, path.basename srcFile
srcDir = process.cwd()

Promise.resolve srcDir
  .then pack.createBundleDescriptor
  .then pack.createBundle
  .then moveTo srcDir
  .then pack.cleanup
