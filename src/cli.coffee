BigPack = require "."
Promise = require "bluebird"
path = require "path"
fs = require "fs"
rename = Promise.promisify fs.rename
writeFile = Promise.promisify fs.writeFile
pack = BigPack()
moveTo = (targetDir) -> (srcFile) -> 
  rename srcFile, path.join targetDir, path.basename srcFile
writeJson = (file)->(obj)->
  if obj?
    writeFile file, JSON.stringify obj, null, "  "
      .then ->
srcDir = process.cwd()

Promise.resolve srcDir
  .then pack.packageJsonWithBundledDependencies
  .then writeJson path.join srcDir, "package.json"
