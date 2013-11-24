//
//  SCWebViewBridge.js
//  SCWebViewBridge
//
//  Created by Sebastien Couture on 2013-11-03.
//  Copyright (c) 2013 Sebastien Couture. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

var SCWebViewBridge = (function()
{
    var _calls;
    
    var call = function( name )
    {
        var args = Array.prototype.slice.call( arguments, 1 );
        _addCall( name, args );
                        
        document.location = "SCWebViewBridge://";
    };
    
    var nextCall = function()
    {
        if( !_calls || 0 === _calls.length )
        {
            return null;
        }
        
        var call;
                       
        try
        {
            call = JSON.stringify( _calls.shift() );
        }
        catch( error )
        {
            alert( "SCWebViewBridge: failed to JSON stringify call " + error );
        }

        return call;
    };
                        
    var callJavascript = function( func, json )
    {               
        if( !json )
        {
            _protectedInvoke( func );
            return;
        }
        
        var args = json.arguments;
        _parseArguments( args );

        _protectedInvoke( func, args );
    };
                       
    function _protectedInvoke( func, args )
    {
        try
        {
            func.apply( null, args );
        }
        catch( error )
        {
            alert( "SCWebViewBridge: failed to call '" + func + "', error:" + error );
        }
    }
                       
    function _parseArguments( args )
    {
        if( !arguments )
        {
            return;
        }
                       
        for( var index = 0; index < args.length; index++ )
        {
            var argument = args[ index ];
                       
            if( argument instanceof String ||
                "string" === typeof argument )
            {
                if( 0 === argument.indexOf( "scd:" ) )
                {
                    var timeMSec = parseInt( argument.substring( 4 ) ) * 1000;
                    args[index] = new Date( timeMSec );
                }
            }
            else if( argument instanceof Array )
            {
                _parseArguments( argument );
            }
            else
            {
                // do nothing
            }
        }
    }
                       
    function _addCall( name, args )
    {
        if( !_calls )
        {
            _calls = [];
        }
        
        _calls.push( { name: name, arguments: args } );
    }
    
    return {
        call: call,
        nextCall: nextCall,
        callJavascript: callJavascript
    }
})();
