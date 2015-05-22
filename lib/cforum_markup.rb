# -*- coding: utf-8 -*-

require 'strscan'

module CforumMarkup
  def cforum2markdown(content)
    doc = StringScanner.new(content)
    ncnt = ''
    coder = HTMLEntities.new
    code_open = 0

    while !doc.eos?
      if doc.scan(/<br \/>-- <br \/>/)
        ncnt << "\n-- \n"

      elsif doc.scan(/(?:<br \/>)+/)
        if doc.matched.length / 6 > 1
          ncnt << "\n" * (doc.matched.length / 6)
        else
          ncnt << "  \n"
        end

      elsif doc.scan(/\u007F/)
        ncnt << '> '

      elsif doc.scan(/(-{2,})|\*/)
        ncnt << '\\' if code_open <= 0
        ncnt << doc.matched

      elsif doc.scan(/<img[^>]+>/)
        data = doc.matched
        alt = ""
        src = ""

        src = $1 if data =~ /src="([^"]+)"/
        alt = $1 if data =~ /alt="([^"]+)"/

        alt = src if alt.blank?

        ncnt << "![#{alt}](#{src})"

      elsif doc.scan(/\[(\w+):?/i)
        save = doc.pos
        directive = doc[1]
        content = ''
        no_end = true

        doc.skip(/\s/)

        while no_end and not doc.eos?
          content << doc.matched if doc.scan(/[^\]\\]/)

          if doc.scan(/\\\]/)
            content << '\]'
          elsif doc.scan(/\\/)
            content << "\\"
          elsif doc.scan(/\]/)
            no_end = false
          end
        end

        # empty directive
        if content.blank?
          ncnt << "[#{directive}:"
          doc.pos = save
          next
        end

        # unterminated directive
        if doc.eos? and no_end
          ncnt << "[#{directive}:"
          doc.pos = save
          next
        end

        case directive
        when 'link', 'ref'
          val = cforum_gen_link(directive, content)
          if val.blank?
            ncnt << "[#{directive}:"
            doc.pos = save
            next
          end

          ncnt << val

        when 'image'
          ncnt << cforum_gen_image(content)

        when 'pref'
          ncnt << cforum_gen_pref(content)
        when 'code'
          val = '~~~'
          code_open += 1

          unless content.blank?
            _, lang = content.split(/=/, 2)
            val << ' ' + lang
          end

          doc.scan(/<br \/>/)

          ncnt << val + "\n"

        end

      elsif doc.scan(/\[code\]/)
        ncnt << "~~~"
        code_open += 1

      elsif doc.scan(/\[\/code\]/)
        if code_open > 0
          code_open -= 1
          ncnt << "\n~~~"
        else
          ncnt << '[/code]'
        end

      else
        ncnt << doc.matched if doc.scan(/./m)
      end
    end

    ncnt.gsub!(/~~~\n(.*)\n~~~/, '`\1`')
    ncnt.gsub!(/~~~\s*(\w+)\n(.*)\n~~~/, '`\2`{: .language-\1}')
    ncnt.gsub!(/(?<!\n)\n~~~/, "\n\n~~~")
    #raise ncnt.inspect

    coder.decode(ncnt)
  end

  def cforum_gen_pref(href)
    href, title = href.split('@title=', 2) if href =~ /@title=/
    t, m = href.split(/(&amp)?;/)

    '[' + (title.blank? ? ('?' + t + '&' + m) : title) + '](/?' + t + "&" + m + ')'
  end

  def cforum_gen_image(href)
    href, title = href.split('@title=', 2) if href =~ /@title=/
    '![' + (title.blank? ? href : title) + "](#{href})"
  end

  def cforum_gen_link(directive, content)
    title = href = nil

    if directive == 'ref'
      ref, href = content.split(';', 2)
      href, title = href.split('@title=', 2) if href =~ /@title=/

      if %w(self8 self81 self811 self812 sel811 sef811 slef812).include?(ref)
        href = "http://de.selfhtml.org/#{href}"
      elsif ref == 'self7'
        href = "http://aktuell.de.selfhtml.org/archiv/doku/7.0/#{href})"
      elsif ref == 'zitat'
        href = "http://community.de.selfhtml.org/zitatesammlung/zitat#{href})"
      else
        return nil
      end

    elsif directive == 'link'
      href = content
      href, title = href.split('@title=', 2) if href =~ /@title=/
    end

    return nil if href.blank?

    '[' + (title.blank? ? href : title) + "](#{href})"
  end
end

# eof
