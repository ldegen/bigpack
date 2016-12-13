describe "The bigpack bundler", ->
  BigPack = require "../src/index"
  Promise = require "bluebird"
  fs = require "fs"
  writeFile = Promise.promisify fs.writeFile
  readFile = Promise.promisify fs.readFile
  access = Promise.promisify fs.access
  path = require "path"
  mkdir = Promise.promisify require "mkdirp"
  rmdir = Promise.promisify require "rimraf"
  srcDir = undefined
  bundleDir = undefined
  tmpDir = undefined
  npmListOutput = 
    name: 'aggregator'
    dependencies:
      'coffee-script': {}
      'csv-parse': {}
      elasticsearch:
        dependencies:
          chalk:
            dependencies:
              'ansi-styles': {}
              'escape-string-regexp': {}
  spawn = (cwd)->(executable, args...)->
    cmd = [executable,args...].join " "
    trace cwd, cmd
    if srcDir == cwd and cmd == "npm ls --json --prod"
      Promise.resolve new Buffer JSON.stringify npmListOutput
    else if cmd == "npm pack"
      writeFile path.join( cwd, "foo-bigpack-2.1.4.tgz"), new Buffer [0,8,21]

    else
      Promise.resolve ""
  history = undefined
  writeJson = (file, data)->
    writeFile file, JSON.stringify data, null, "  "
  readJson = (file)->
    readFile file
      .then (data)->JSON.parse data
  trace = (args...) -> history.push args
  bundleDescriptor = undefined
  packageDescriptor =
    name: "aggregator"
    version: "2.1.4"
    description: "my foo is special"
    author: "bar"
    license: "ISC"
    dependencies:
      oink: "^1.0.0"
      umf: "^2.0.0"

  pack = undefined
  beforeEach ->
    history = []
    tmpDir = tmpFileName()
    srcDir = path.join tmpDir, "orig"
    bundleDir = path.join tmpDir, "bundle"
    bundleDescriptor =
      name: "aggregator-bigpack"
      version: "2.1.4"
      description: "A bundled version of aggregator and all its dependencies"
      author: "bar"
      license: "ISC"
      dependencies:
        aggregator: srcDir
      bundledDependencies:[
        "aggregator"
        "coffee-script"
        "csv-parse"
        "elasticsearch"
        "chalk"
        'ansi-styles'
        'escape-string-regexp'
      ]
    pack = BigPack
      spawn:spawn
      tmpDir: -> Promise.resolve bundleDir

    mkdir bundleDir
      .then -> mkdir srcDir
      .then -> writeJson path.join(srcDir, "package.json"), packageDescriptor


  describe "given a source directory containing a package.json file", ->
    it "runs 'npm install' on the original package to make sure all dependencies are resolved", ->
      p = pack.createBundleDescriptor srcDir
      expect(p).to.be.fulfilled.then ->
        expect(history).to.eql [
          [srcDir,"npm install"]
          [srcDir,"npm ls --json --prod"]
        ]

    it "creates a new package.json referencing the transitive
        closure of the original dependencies as 'bundledDependencies'", ->
      p = pack.createBundleDescriptor srcDir
      expect(p).to.eventually.eql bundleDescriptor



  describe "given a bundle descriptor", ->
    it "writes the descriptor to a temporary working directory", ->
      p = pack
        .createBundle bundleDescriptor
        .then -> readJson path.join bundleDir, "package.json"
      expect(p).to.eventually.eql bundleDescriptor

    it "runs 'npm install' and 'npm pack' in that directory", ->
      expect(pack.createBundle bundleDescriptor).to.be.fulfilled.then ->
        expect(history).to.eql [
          [bundleDir,"npm install"]
          [bundleDir,"npm pack"]
        ]

    it "will return the full path to the created tarball", ->
      expect(pack.createBundle bundleDescriptor).to.eventually.eql path.join bundleDir, "aggregator-bigpack-2.1.4.tgz"



  describe "when asked to clean up", ->
    it "will recursively delete the bundleDir", ->
      expect(pack
        .createBundle bundleDescriptor
        .then pack.cleanup
      ).to.be.fulfilled.then ->
        expect(access bundleDir).to.be.rejected
