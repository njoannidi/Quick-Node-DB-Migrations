var pg = require('pg');
var fs = require('fs');
var errorHandler = require('../bin/errorHandler.js');

module.exports.connect = function(credentials, cb)
{
	pg.connect('postgres://'+credentials.username+':'+credentials.password+'@'+credentials.host+'/'+credentials.database, 
		function(err, newClient, done)
		{
			if(err){return errorHandler.onErr(err);}
			
			process.stdout.write('Successful'.green+'\n');
			if(cb) { cb(newClient); }
			
		});
};

module.exports.setSchema = function(client, schema, cb)
{
	console.log('\nSetting Schema to: '.green + credentials.schema);
	client.query('SET search_path TO "'+credentials.schema+'"', 
		function(err, result)
		{
			if(err){errorHandler.onErr(err);}
			if(cb) { cb(); }
		});
};

module.exports.beginTransaction = function(client, cb)
{
	client.query('BEGIN;', function(err,result)
		{
			if(err) {return errorHandler.onErr(err);}
			if(cb) { cb(); }
			
		});
};

module.exports.rollback = function(client, success, failure)
{
	client.query('ROLLBACK;', function(err, result)
		{
			if(err && failure)
			{
				failure();
			} 
			else if(success)
			{
				success();
			}
		});
};

module.exports.commit = function(client, cb)
{
	client.query('COMMIT;', function(err,result)
	{
		if(err) {return errorHandler.handleDbError(err);}
			if(cb) { cb(); }
	});
};

module.exports.processFile = function(client, sqlFile, cb)
{
	client.query(sqlFile, function(err, result)
	{
		if(err) {return errorHandler.handleDbError(err, result, client, currFile);}
		process.stdout.write(' Successful'.green);
		if(cb) { cb(); }
	});	
};
