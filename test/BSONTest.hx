import haxe.Int64;
import org.bsonspec.BSON;
import org.bsonspec.BSONDocument;
import org.bsonspec.MongoDate;
import org.bsonspec.ObjectID;
import sys.io.File;
using haxe.Int64;

class BSONTest extends TestCase
{

	function testEncodeDecode()
	{
		var data = {
			_id: new ObjectID(),
			title: 'My awesome post',
			hol: [10, 2, 20.5],
			int64: Int64.ofInt(1),
			lint64: Int64.make(1<<31, 0),  // smallest int64
			options: {
				delay: 1.565,
				test: true,
				nested: [
					{
						going: 'deeper',
						mining: -35
					}
				]
			},
			date: Date.now(),
			int: 2147483647,
			float: 2147483647.0,
			monkey: null,
			bool: true
		};

		var out = BSON.decode(new haxe.io.BytesInput(BSON.encode(data)));

		assertSame(data, out);

		// overflow (-2)
		assertSame(data.int + data.int, out.int + out.int);

		// no overflow
		assertSame(data.float + data.float, out.float + out.float);

		assertSame(data._id.getDate(),  out._id.getDate());
	}

	function testBSONDocument()
	{
		var doc:BSONDocument = BSONDocument.create()
			.append( "_id", new ObjectID() )
			.append( "title", 'My awesome post' )
			.append( "hol", ['first', 2, Date.now()] )
			.append( "int64", Int64.ofInt(1) )
			.append( "lint64", Int64.make(1<<31, 0))  // smallest int64
			.append( "options", BSONDocument.create()
				.append( "delay", 1.565 )
				.append( "test", true )
				.append( "nested", [
					53,
					BSONDocument.create()
						.append( "going", 'deeper' )
						.append( "mining", -35 )
					] )
				)
			.append( "monkey", null )
			.append( "$in", [1, 3] );

		// File.saveBytes("test-doc.bson", BSON.encode( doc ) );
		// File.saveContent("test-doc.txt", doc.toString() );

		// var out:Dynamic = BSON.decode(File.read("test.bson", true));
        assertFalse(false);
	}

	@:access(org.bsonspec.MongoDate)
	function testMongoDate()
	{
		function log2(v:Float)
		{
			return Math.log(v)/Math.log(2);
		}

		function test(high:Int, low:Int)
		{
			var date = (Int64.make(high, low) : MongoDate);
			var cal = date.getTimeInt64();

			#if (haxe_ver < 3.2)

			assertEquals(high, Int64.getHigh(cal));
			#if neko  // on neko Date has 1000 ms precision
			assertEquals(Math.floor(low/1000), Math.floor(Int64.getLow(cal)/1000));
			#else
			assertEquals(low, Int64.getLow(cal));
			#end

			#else

			assertEquals(high, cal.high);
			#if neko  // on neko Date has 1000 ms precision
			assertEquals(Math.floor(low/1000), Math.floor(cal.low/1000));
			#else
			assertEquals(low, cal.low);
			#end

			#end
		}

		test(0, 1000);  // 1 second
		test(0, 0x7fffffff);
		test(0, 0xffffffff);
		test(0, 1000*3600*24);  // 1 day
		test(0x007, 0x57B12C00);  // 365 days
		test(0x148, 0xED0DAAE8);  // some time at 7 Oct 2014
		test(0x148, 0xED203CD0);  // some other time at 7 Oct 2014
	}

}
