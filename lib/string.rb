class String
  
  class << self
    def random(count = 6, ranges = [('a'..'z'),('A'..'Z'),('0'..'9')])
      o =  ranges.map{|i| i.to_a}.flatten;  
      string  =  (0..(count-1)).map{ o[rand(o.length)]  }.join;
    end
  end
  
  def left(count)
    self.slice(0,count)
  end
  
  def right(count)
    self.slice(-count,count)
  end
  
  def left_trim
    # remove leading whitespace
    self.gsub(/^[\t\s]+/, '')
  end
  
  def right_trim
    # remove trailing whitespace
    self.gsub(/[\t\s]+$/, '')
  end
  
  def trim
    # remove leading and trailing whitespace
    self.left_trim.right_trim
  end

  # html = <<-stop.here_with_pipe
  #   |<!-- Begin: comment  -->
  #   |<script type="text/javascript">
  # stop
  def here_with_pipe(linefeeds = false)
    lines = self.split("\n")
    lines.map! {|c| c.sub!(/\s*\|/, '')}
    new_string = lines.join(linefeeds ? "\n" : " ")
    self.replace(new_string)
  end

  def is_alpha_numeric?
    regex = /^[a-zA-Z0-9]+$/
    return (self =~ regex) == 0 ? true : false
  end

  def is_email_address?
    # //Email address
    # //Use this version to seek out email addresses in random documents and texts.
    # //Does not match email addresses using an IP address instead of a domain name.
    # //Does not match email addresses on new-fangled top-level domains with more than 4 letters such as .museum.
    # //Including these increases the risk of false positives when applying the regex to random documents.
    # '\b[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b'
    # 
    # //Email address (anchored)
    # //Use this anchored version to check if a valid email address was entered.
    # //Does not match email addresses using an IP address instead of a domain name.
    # //Does not match email addresses on new-fangled top-level domains with more than 4 letters such as .museum.
    # //Requires the "case insensitive" option to be ON.
    # '^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$'
    # 
    # //Email address (anchored; no consecutive dots)
    # //Use this anchored version to check if a valid email address was entered.
    # //Improves on the original email address regex by excluding addresses with consecutive dots such as john@aol...com
    # //Does not match email addresses using an IP address instead of a domain name.
    # //Does not match email addresses on new-fangled top-level domains with more than 4 letters such as .museum.
    # //Including these increases the risk of false positives when applying the regex to random documents.
    # '^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$'
    # 
    # //Email address (no consecutive dots)
    # //Use this version to seek out email addresses in random documents and texts.
    # //Improves on the original email address regex by excluding addresses with consecutive dots such as john@aol...com
    # //Does not match email addresses using an IP address instead of a domain name.
    # //Does not match email addresses on new-fangled top-level domains with more than 4 letters such as .museum.
    # //Including these increases the risk of false positives when applying the regex to random documents.
    # '\b[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}\b'
    # 
    # //Email address (specific TLDs)
    # //Does not match email addresses using an IP address instead of a domain name.
    # //Matches all country code top level domains, and specific common top level domains.
    # '^[A-Z0-9._%-]+@[A-Z0-9.-]+\.(?:[A-Z]{2}|com|org|net|biz|info|name|aero|biz|info|jobs|museum|name)$'
    # 
    # //Email address: Replace with HTML link
    # '\b(?:mailto:)?([A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4})\b'
    
    email_regex = %r{^[A-Z0-9._%-]+@[A-Z0-9.-]+\.(?:[A-Z]{2}|com|org|net|biz|info|name|aero|jobs|museum|edu|pro)$}xi # Case insensitive
    
    return (self =~ email_regex) == 0 ? true : false
  end
  
  def is_zipcode?
    self =~ %r{^(\d{5})(-\d{4})?$}x ? true : false
  end

  def format_phone
    '(' << slice(0..2) << ')' << slice(3..5) << '-' << slice(-4,4)
  end

  def is_numeric?
    begin
      Float(self)
    rescue
      false # not numeric
    else
      true # numeric
    end
  end

  def sanitize
    clean_string = self.gsub(/[^a-z0-9,! \-\(\)\:\;\.\&\$]+/i, '')
    #p "SAN: #{clean_string}"
    clean_string
  end

  def shorten(count = 30)
    if self.length >= count
      shortened = self[0, count]
      splitted = shortened.split(/\s/)
      words = splitted.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      self
    end
  end

  def escape_single_quotes
    self.gsub(/[']/, '\\\\\'')
  end
  
end
