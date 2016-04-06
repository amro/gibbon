# gibbon

Gibbon is an API wrapper for MailChimp's [API](http://kb.mailchimp.com/api/).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.svg)](http://travis-ci.org/amro/gibbon)
[![Dependency Status](https://gemnasium.com/amro/gibbon.svg)](https://gemnasium.com/amro/gibbon)
##Important Notes

Gibbon now targets MailChimp API 3.0, which is substantially different from the previous API. Please use Gibbon 1.1.x if you need to use API 2.0.

Please read MailChimp's [Getting Started Guide](http://kb.mailchimp.com/api/article/api-3-overview).

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

First, create an Request instance Gibbon::Request:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key")
```

You can set an individual request's timeout with:

```ruby
gibbon.timeout = 10
```

Alternatively you can set `api_key` and `timeout` globally which is useful in a Rails app. Put the following in a initializer file such as ***your\_app/config/initializers/gibbon.rb***

```ruby
Gibbon::Request.api_key = "your_api_key"
Gibbon::Request.timeout = 15
```

Assuming you've set an `api_key` on Gibbon, you can make API calls on the class itself:

```ruby
Gibbon::Request.lists.retrieve
```

You can also set the environment variable `MAILCHIMP_API_KEY` and Gibbon will use it when you create an instance:

```ruby
gibbon = Gibbon::Request.new
```

###Constructing a request
Gibbon uses some [method_missing](http://rubylearning.com/satishtalim/ruby_method_missing.html) magic to so you can make requests using the resources defined in the [MailChimp's docs](http://kb.mailchimp.com/api/resources). Resource ID's
are specified inline and a [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) (`create`, `retrieve`, `update`, `upsert`, or `delete`) verb initiates the request. For example:

	gibbon.campaigns.create( params )

performs a `create` action on the `/campaigns` resource passing in `params`. 

And:

	gibbon.file_manager.files.retrieve

performs a `retrieve` (read) action on the `/file-manager/files` resource. 

###Note
1. `upsert` updates a record if it exists and if supported by the Mailchimp API will create it if it doesn't exist.
2. If an API endpoint uses dashes `-` such as `/file-manager/files` you should use underscores to call it `gibbon.file_manager.files.retrieve`


###More complex requests
You can specify `headers`, `params`, and `body` when calling a **CRUD** method. For example:

```ruby
gibbon.lists.retrieve(headers: {"SomeHeader": "SomeHeaderValue"}, params: {"query_param": "query_param_value"})
```

`body` is only supported on `create`, `update`, and `upsert` calls. Those map to HTTP `POST`, `PATCH`, and `PUT` verbs respectively.

MailChimp's [resource documentation](http://kb.mailchimp.com/api/resources) contains a full list of available resources. 

## Examples

### Lists

Fetch all lists:

```ruby
gibbon.lists.retrieve
```

Retrieving a specific list looks like:

```ruby
gibbon.lists(list_id).retrieve
```

Retrieving a specific list's members looks like:

```ruby
gibbon.lists(list_id).members.retrieve
```

### Subscribers

Get all subscribers for a list:

```ruby
gibbon.lists(list_id).members.retrieve
```

By default V3 of the Mailchimp API only returns 10 results. For 50 results use:

```ruby
gibbon.lists(list_id).members.retrieve(params: {"count": "50"})
```

For the next 50 results (members 51-100) use: 

```ruby
gibbon.lists(list_id).members.retrieve(params: {"count": "50", "offset: "50"})
```

For all the resuts you need two calls :
```ruby
number_of_list_members = gibbon.lists(list_id).members.retrieve["total_items"]
gibbon.lists(list_id).members.retrieve(params: {count: "#{number_of_list_members}"})
```
Subscribe a member to a list:

```ruby
gibbon.lists(list_id).members.create(body: {email_address: "foo@bar.com", status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
```

If you want to `upsert` instead, you would do the following:

```ruby
gibbon.lists(list_id).members(lower_case_md5_hashed_email_address).upsert(body: {email_address: "foo@bar.com", status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
```

You can also unsubscribe a member from a list:

```ruby
gibbon.lists(list_id).members(lower_case_md5_hashed_email_address).update(body: { status: "unsubscribed" })
```

### Campaigns

Get all campaigns:

```ruby
campaigns = gibbon.campaigns.retrieve
```

Fetch the number of opens for a campaign

```ruby
email_stats = gibbon.reports(campaign_id).retrieve["opens"]
```

Create a new campaign:

```ruby
recipients = {
  list_id: list_id,
  segment_opts: {
    saved_segment_id: segment_id
  }
}
settings = {
  subject_line: "Subject Line",
  title: "Name of Campaign",
  from_name: "From Name",
  reply_to: "my@email.com"
}

body = {
  type: "regular",
  recipients: recipients,
  settings: settings
}

begin
  gibbon.campaigns.create(body: body)
rescue Gibbon::MailChimpError => e
  puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
end
```

Add content to a campaign:

*(Please note that Mailchimp does not currently support dynamic replacement of mc:edit areas in their drag-and-drop templates using their API.  Custom templates [can be used](http://stackoverflow.com/questions/29366766/mailchimp-api-not-replacing-mcedit-content-sections-using-ruby-library) instead.)*

```ruby
body = {
  template: {
    id: template_id,
    sections: {
      "name-of-mc-edit-area": "Content here"
    }
  }
}

gibbon.campaigns(campaign_id).content.upsert(body: body)
```

Send a campaign:

```ruby
gibbon.campaigns(campaign_id).actions.send.create
```

### File Manager

List all files:

```ruby
gibbon.file_manager.files.retrieve
```
Actaul API call : `GET /file-manager/files`

Delete a file:

```ruby
gibbon.file_manager.files(file_id).delete
```
Actaul API call : `DELETE /file-manager/files/{file_id}`

Upload a file:

```ruby
file_in_base64 = Base64.encode64(File.open("path/to/yourfile.jpg", "rb").read)
gibbon.file_manager.files.create(body:{folder_id: folder_id, name: "yourfile.jpg", file_data: file_in_base64})
```

### Interests

Interests are a little more complicated than other parts of the API, so here's an example of how you would set interests during at subscription time or update them later. The ID of the interests you want to opt in or out of must be known ahead of time so an example of how to find interest IDs is also included.

Subscribing a member to a list with specific interests up front:

```ruby
g.lists(list_id).members.create(body: {email_address: user_email_address, status: "subscribed", interests: {some_interest_id: true, another_interest_id: true}})
```

Updating a list member's interests:

```ruby
gibbon.lists(list_id).members(member_id).update(body: {interests: {some_interest_id: true, another_interest_id: false}})
```

So how do we get the interest IDs? When you query the API for a specific list member's information:

```ruby
g.lists(list_id).members(member_id).retrieve
```

The response looks someting like this (unrelated things removed):

```ruby
{"id"=>"...", "email_address"=>"...", ..., "interests"=>{"3def637141"=>true, "f7cc4ee841"=>false, "fcdc951b9f"=>false, "3daf3cf27d"=>true, "293a3703ed"=>false, "72370e0d1f"=>false, "d434d21a1c"=>false, "bdb1ff199f"=>false, "a54e78f203"=>false, "c4527fd018"=>false} ...}
```

The API returns a map of interest ID to boolean value. Now we to get interest details so we know what these interest IDs map to. Looking at [this doc page](http://kb.mailchimp.com/api/resources/lists/interest-categories/interests/lists-interests-collection), we need to do this:

```ruby
g.lists(list_id).interest_categories.retrieve
```

To get a list of interest categories. That gives us something like:

```ruby
{"list_id"=>"...", "categories"=>[{"list_id"=>"...", "id"=>"0ace7aa498", "title"=>"Food Preferences", ...}] ...}
```

In this case, we're interested in the ID of the "Food Preferences" interest, which is `0ace7aa498`. Now we can fetch the details for this interest group:

```ruby
g.lists(list_id).interest_categories("0ace7aa498").interests.retrieve
```

That response gives the interest data, including the ID for the interests themselves, which we can use to update a list member's interests or set them when we call the API to subscribe her or him to a list.

### Error handling

Gibbon raises an error when the API returns an error.

Gibbon::MailChimpError has the following attributes: `title`, `detail`, `body`, `raw_body`, `status_code`. Some or all of these may not be
available depending on the nature of the error.

### Other

Overriding Gibbon's API endpoint (i.e. if using an access token from OAuth and have the `api_endpoint` from the [metadata](http://apidocs.mailchimp.com/oauth2/)):

```ruby
Gibbon::Request.api_endpoint = "https://us1.api.mailchimp.com"
Gibbon::Request.api_key = your_access_token_or_api_key
```

You can set an optional proxy url like this (or with an environment variable MAILCHIMP_PROXY):

```ruby
gibbon.proxy = 'http://your_proxy.com:80'
```

You can set a different [Faraday adapter](https://github.com/lostisland/faraday) during initialization:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key", faraday_adapter: :net_http)
```

### Migrating from Gibbon 1.x

Gibbon 2.x has different syntax from version 1.x. This is because Gibbon maps to MailChimp's API and because version 3 of the API is quite different from version 2. First, the name of the primary class has changed from `API` to `Request`. And the way you pass an API key during initialization is different. A few examples below.

#### Initialization

Gibbon 1.x:

```ruby
gibbon = Gibbon::API.new("your_api_key")
```
    
Gibbon 2.x:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key")
```

MailChimp API 3 is a RESTful API, so Gibbon's syntax now requires a trailing call to a verb, as described above.

#### Fetching Lists

Gibbon 1.x:

```ruby
gibbon.lists.list
```
    
Gibbon 2.x:

```ruby
gibbon.lists.retrieve
```

#### Fetching List Members

Gibbon 1.x:

```ruby
gibbon.lists.members({:id => list_id})
```
    
Gibbon 2.x:

```ruby
gibbon.lists(list_id).members.retrieve
```

#### Subscribing a Member to a List

Gibbon 1.x:

```ruby
gibbon.lists.subscribe({:id => list_id, :email => {:email => "foo@bar.com"}, :merge_vars => {:FNAME => "Bob", :LNAME => "Smith"}})
```
    
Gibbon 2.x:

```ruby
gibbon.lists(list_id).members.create(body: {email_address: "foo@bar.com", status: "subscribed", merge_fields: {FNAME: "Bob", LNAME: "Smith"}})
```

## Thanks

Thanks to everyone who has [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development.

## Copyright

* Copyright (c) 2010-2016 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2016 The Rocket Science Group.
