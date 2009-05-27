changesets.each do |changeset|
  feed.entry(changeset, :url => hosted_url(changeset.repository, :changeset, changeset)) do |entry|
    #mike was on the next line to get rid of bad truncate fn
    entry.title("[#{changeset.revision}] #{changeset.message.slice(0,75) + (changeset.message.length > 75 ? '...' : '')} by #{changeset.author}")
    entry.summary(simple_format(h(changeset.message)), :type => :html)
    entry.content("<ul>#{render :partial => "changesets/changes", :locals => { :changeset => changeset, :changes => changeset.changes.paginate }}</ul>", :type => 'html')
    entry.updated(changeset.changed_at.xmlschema)
    entry.author do |author|
      author.name(changeset.author)
    end
  end
end