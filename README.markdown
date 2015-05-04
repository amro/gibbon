# gibbon with streaming capibilities

[Gibbon](https://github.com/amro/gibbon) is an API wrapper for MailChimp's [Primary and Export APIs](http://www.mailchimp.com/api).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)
[![Dependency Status](https://gemnasium.com/amro/gibbon.png)](https://gemnasium.com/amro/gibbon)

# About this Fork


## Why this fork?
The export wrapper of the Mailchimp API wrapper "Gibbon" loads all the exported data first in memory, before returning it. Since with exporting data, there can be lots and lots of data, this seemed fairly inefficient. This fork solves this.

## How is this fork different?
The changes are as following:
* Instead of httparty, the basic net::http interface is used to stream data directly from the Mailchimp API.
* The export API functions now require a &block to feed each row of data to.
* The export test functions use webmock to fake and verify net::http requests.
* Some re-arrangement of functions (parse_response at APICategory.rb)

## What can I do with this fork?
All you can do with the normal Gibbon API Wrapper. Plus, parsing each row of exported data while it is being received from the export API:
```
    ge = Gibbon::Export.new("your_api_key")
    ge.list({:id => *list_id*}) { |row| *do_sth_with* row }
```

It is important to supply an explicit block / procedure to the export functions, not an implicit one. So, the preceding and following one will work. Please note this method also includes a counter (*i*, starting at 0) telling which row of data you're receiving:
```
    method = Proc.new do |row, i|
        *do_sth_with* row
    end
    ge.list(params, &method)
```

Please note, the following example gives a block that is outside of the function and therefore **won't** work:
```
    ge.list({:id => *list_id*}) do |row|
        *do_sth_with* row
    end
```

And, the original way of working with gibbon is still functional of course:
```
    list = ge.list({:id => *list_id*})
```

## Some final words
Happy coding!

* Copyright (c) 2015 Frans van der Sluis.
* Copyright (c) 2010-2014 Amro Mousa.
* MailChimp (c) 2001-2014 The Rocket Science Group.

See LICENSE.txt for details.
