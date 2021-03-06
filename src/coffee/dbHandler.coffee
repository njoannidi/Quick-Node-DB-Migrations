fs = require 'fs'
errorHandler = require './errorHandler.js'
manifest = require './manifest'

dbHandler =
   beginMigration: (credentials, filesToProcess) ->

      if !fs.existsSync __dirname+'/orms/'+credentials.type+'.js'
         process.stdout.write '\nDatabase Type: '.red + credentials.type + ' not supported.\n Supported types: mysql, pgsql\n'
         process.exit 1

      @credentials = credentials
      @currentFile = 0
      @files = filesToProcess
      @database = require __dirname+'/orms/'+credentials.type+'.js'

      process.stdout.write '\nConnecting as '.green + credentials.username + ' ... '

      @database.connect credentials,
         (dbClient) ->
            # Success
            if credentials.schema
                  dbHandler.database.setSchema dbClient, credentials.schema,
                     (client) ->
                        dbHandler.database.beginTransaction client
                           , ->
                              # Success
                              dbHandler.processFiles client
                           , errorHandler.handleDbError
            else
               dbHandler.database.beginTransaction dbClient
                  , ->
                     # Success
                     dbHandler.processFiles dbClient
                  , dbHandler.processFiles

         , (err) ->
            # Failure
            errorHandler.onErr err

   processFiles: (dbClient) ->
      currFile = @files[@currentFile]

      process.stdout.write '\nProcessing file: '.green + currFile.name.yellow+' ...'.green
      sqlFile = fs.readFileSync(currFile.name).toString()


      @database.processFile dbClient, sqlFile,
         (dbClient)->
            # Success
            ++dbHandler.currentFile;
            if dbHandler.files.length > dbHandler.currentFile
               dbHandler.processFiles dbClient
            else
               dbHandler.migrationComplete dbClient
         , (err, client, dbInterface) ->
            # Failure
            errorHandler.handleDbError err,
               client,
               dbInterface,
               currFile,
               dbHandler.files,
               dbHandler.credentials

   migrationComplete:
      (dbClient) ->
         dbHandler.database.commit dbClient,
            ->
               # Success
               console.log '\nMigration Complete'.green
               manifest.process dbHandler.files, dbHandler.credentials, true
               process.exit 0
            , (err, client) ->
               # Failure
               errorHandler.handleDbError err, client

module.exports = dbHandler
