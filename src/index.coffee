Promise = require "bluebird"
cp = require "child_process"
execFile = Promise.promisify cp.execFile
readFile = Promise.promisify require("fs").readFile
writeFile = Promise.promisify require("fs").writeFile
mkdir = Promise.promisify require "mkdirp"
rmdir = Promise.promisify require "rimraf"
path = require "path"

spawn0 = (cwd, env) -> (executable, args...)->
  execFile executable, args, cwd:cwd, env:env

tmpFileName = ->
  crypto = require("crypto")
  buf = crypto.randomBytes(20)
  path.join require("os").tmpdir(), buf.toString("hex")
  
tmpDir0 = -> 
  name = tmpFileName()
  mkdir name
    .then ->name
  
writeJson = (file, data)->
  writeFile file, JSON.stringify data, null, "  "


searchTreeForDeps = (obj)->[obj.name,(searchDeps obj.dependencies)...]
searchDeps = (deps = {})->
  lists = for key,value of deps
    [key,(searchDeps value.dependencies)...]
  [].concat lists...

module.exports = ({spawn=spawn0,tmpDir=tmpDir0}={}) ->
  tmpDirs = []
  createBundleDescriptor: (srcDir0)->
    srcDir = path.resolve srcDir0
    spawnInSrcDir = spawn(srcDir, process.env)
    Promise.all [
      readFile path.join srcDir, "package.json"
        .then JSON.parse
      spawnInSrcDir "npm", "install"
        .then -> spawnInSrcDir "npm", "ls", "--json", "--prod"
        .then JSON.parse
        .then searchTreeForDeps 
    ]
      .then ([{name, version, author, license}, dependencies])->
        name: name+"-bigpack"
        version: version
        description: "A bundled version of #{name} and all its dependencies"
        author: author
        license: license
        dependencies:
          "#{name}": srcDir
        bundledDependencies: dependencies

  createBundle: (bundleDescriptor)->
    tmpDir().then (dir)->
      tmpDirs.push dir
      spawnInBundleDir = spawn dir, process.env
      writeJson path.join(dir, "package.json"), bundleDescriptor
        .then -> spawnInBundleDir "npm", "install"
        .then -> spawnInBundleDir "npm", "pack"
        .then -> 
          {name,version}=bundleDescriptor
          path.join dir,"#{name}-#{version}.tgz"
  

  cleanup: ->
    Promise.all tmpDirs.map (dir)->rmdir dir
