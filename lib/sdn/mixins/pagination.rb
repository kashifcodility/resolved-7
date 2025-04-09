require 'uri'
require 'cgi'

module SDN::Mixins::Pagination

    const_def :DEFAULT_PER_PAGE, 20

    module Exceptions
        class Error < RuntimeError; end
        class ArgumentError < Error; end
    end
    include SDN::Mixins::Pagination::Exceptions

    # PaginatedCollection object:: extends array with extra stuff (page, pages,
    # per_page, count) added to the array of data records (typically hashes
    # holding a named set of record elements/db-columns).  Simplifies setting up
    # and adding paging to views for collections having a large number of
    # records.
    class PaginatedCollection < Array

        attr_reader :page
        attr_reader :per_page
        attr_reader :count
        attr_reader :pages

        def initialize( options={} )
            @page     = options[:page].to_i
            @per_page = options[:per_page].to_i
            @count    = options[:count].to_i
            @pages    = options[:pages].to_i

            self.replace( options[:collection] )
        end

    end


    # method for setting up a datamapper model for pagination.  Gets page,
    # per_page, sets up the model query with paging, gets the record count, then
    # instantiates the a paginated collection on the model.
    def paginated_collection( model, opts={}, &block )
        opts=opts.dup

        # allow dynamic input parameter naming for page + per-page if no current
        # page is specified, default to the first page
        opts[:page]     ||= params[opts[:page_name]     || 'page']     || 1
        opts[:per_page] ||= params[opts[:per_page_name] || 'per_page'] || DEFAULT_PER_PAGE
        opts[:count]    = model.count
        opts[:pages]    = ( opts[:count].to_f / opts[:per_page].to_i ).ceil rescue 1

        page = opts[:page].to_i.min(1)
        count = opts[:per_page].to_i
        if model.count == 0
            # this will also work for empty Arrays
            collection = model
        elsif model.is_a?(Mongoid::Criteria) # Walks like a Mongoid duck. Now: is it sorted right?
            collection = model.skip((page - 1) * count).limit(count).to_a
        elsif model.respond_to?(:paginate)
            # NOTE: Datamapper is smart enough to not fire off a query until we
            #       act upon 'model' here.  That means that we can pass in a
            #       filtered model such as Order.all(:type => "balls") and not
            #       suffer any performance loss when we glom on .paginate
            collection = model.paginate( :page => page, :count => count ).to_a
        elsif model.respond_to?(:entries)
            # Handles any enumerator. Probably *very* slowly if it's a database
            # enumerator.  But sometimes its handier for some wackier mongoid
            # queries.
            offset = (page - 1) * count
            range = offset + count
            collection = model.entries[offset..range]
        else
            raise ArgumentError,"cannot paginate #{model.inspect}"
        end

        collection.map!(&block) if block_given?
        return PaginatedCollection.new( opts.merge( :collection => collection ) )
    end


    # method for wrapping a paginator object on a paginated_collection object.  Sets up the paginator
    # to handle the url link and html generation.
    def paginator( model, opts={}, &block )
        opts=opts.dup

        opts[:page_name]     ||= opts[:page_name]     || 'page'
        opts[:per_page_name] ||= opts[:per_page_name] || 'per_page'
        url                  ||= opts[:url]           || request.url

        uri                  = URI.parse( url )
        opts[:base_url]      = '//' + uri.host + uri.path
        opts[:query]         = Hash[CGI.parse( uri.query.to_s ).map{|k,v|[k, v.first]}]

        collection = paginated_collection( model, opts, &block )
        return Paginator.new( opts.merge( :collection => collection ) )
    end


    # ---------------------------------------------------------------------
    # methods for specific hardwired pagination methods GO HERE
    # ---------------------------------------------------------------------
    # method to build a specialized formatted paginationg group
    def pagination_html( paginator, opts={} )
        return [
            paginator.start_page(opts),
            paginator.first_page( 'First' ),
            "&nbsp;",
            paginator.prev_page( '&#x2190;' ),
            "&nbsp;",
            paginator.page_list( 5 ),
            "&nbsp;",
            paginator.next_page( '&#x2192;' ),
            "&nbsp;",
            paginator.last_page( 'Last' ),
            "&nbsp;",
            "(",
            paginator.items_page( 10, '-', '+' ),
            ")&nbsp;",
            paginator.close_page(),
        ].join('')
    end


    # ---------------------------------------------------------------------
    # 2 methods for basic erb DSL-like pagination format construction
    # ---------------------------------------------------------------------
    # usage: (in the *.erb file ...)
    #    <% pagination_controls( paginator ) do |p| %>
    #        <%= paginator.first_page 'First' %>
    #        <%= paginator.back_page( 10, 'Prev' ) %>
    #        <%= paginator.page_list 10 %>
    #        <%= paginator.jump_page( 10, 'Next') %>
    #        <%= paginator.last_page 'Last' %>
    #        <%= paginator.items_page( 5, 'Show', 'Per Page' ) %>
    #    <% end %>
    #
    # Requires a Paginator object
    def pagination_controls( paginator, opts={}, &block )
        is_paginator = paginator.is_a?(Paginator)

        if block_given?
            buffer_write(paginator.start_page(opts)) if is_paginator
            yield paginator
            buffer_write(paginator.close_page) if is_paginator
        else
            buffer_write(pagination_html( paginator, opts )) if is_paginator
        end

        return nil
    end


    def buffer_write(content)
        @_out_buf.concat(content)
        return nil
    end


    # Paginator object:: wraps and extends PaginatedCollection with url,
    # url-query related info; plus pagination component formatting methods.
    class Paginator
        include Enumerable

        attr_reader :paged_collection
        attr_reader :page_name
        attr_reader :per_page_name
        attr_reader :base_url
        attr_reader :query

        def initialize( options={} )
            @paged_collection = options[:collection]
            @page_name        = options[:page_name]
            @per_page_name    = options[:per_page_name]
            @base_url         = options[:base_url]
            @query            = options[:query]

            @query.merge!( { @page_name => page, @per_page_name => per_page } )
        end

        # forwarded reader methods
        def page()       @paged_collection.page end
        def pages()      @paged_collection.pages end
        def per_page()   @paged_collection.per_page end
        def count()      @paged_collection.count end
        alias :size :count
        def each(&block) @paged_collection.each(&block) end
        def empty?()     @paged_collection.empty? end

        # ==== pagination link genration methods =======================
        # simple pagination link generation methods
        def first_link() @base_url + query_string( @query.merge( @page_name => 1 ) ) end
        def prev_link()  @base_url + query_string( @query.merge( @page_name => page.pred.min(1) ) ) end
        def next_link()  @base_url + query_string( @query.merge( @page_name => page.succ.max(pages) ) ) end
        def last_link()  @base_url + query_string( @query.merge( @page_name => pages ) ) end

        # longer jump pagination link generation methods
        def jump_back_link( count ) @base_url + query_string( @query.merge( @page_name => (page-count).min(1) ) ) end
        def jump_next_link( count ) @base_url + query_string( @query.merge( @page_name => (page+count).max(pages) ) ) end

        # pagination link generation methods: number of items on the page, up or down by delta
        def less_link( delta ) @base_url + query_string( @query.merge( @page_name => 1, @per_page_name => (per_page-delta.to_i).min(5) ) ) end
        def more_link( delta ) @base_url + query_string( @query.merge( @page_name => 1, @per_page_name => (per_page+delta.to_i).max(count) ) ) end

        # returns an array of page number links to make page list pagination
        # links.  Returns empty array if beyond the end of collection.
        def page_number_links( count )
            pnl = []
            return( pnl ) if( page + 1 >= pages )
            start = page + 1
            stop = (page + count).max(pages)
            (start..stop).each { |p| pnl << @base_url + query_string( @query.merge( @page_name => p ) ) }
            return pnl
        end

        # Builds a url query string using the input query-hash.
        def query_string( q )
            qs = '?'
            q.each { | k, v | qs << CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s) + '&' }
            return qs.chop
        end


        # ==== pagination link-html genration methods =======================
        def start_page(opts={}) %Q{<div class="pagination_controls #{opts[:class]}">} end

        def first_page( label ) link_html( first_link, label, :class => 'first' ) end
        def prev_page( label ) link_html( prev_link, label, :class => 'prev' ) end
        def back_page( count, label ) link_html( jump_back_link( count ), label, :class => 'back' ) end

        def page_list( spread )
            ('[' + page.to_s + '] ' + page_number_link_html( page_number_links( spread ), page ) + ' of ' + pages.to_s)
        end

        def jump_page( count, label ) link_html( jump_next_link( count ), label, :class => 'jump' ) end
        def next_page( label ) link_html( next_link, label, :class => 'next' ) end
        def last_page( label ) link_html( last_link, label, :class => 'last' ) end

        def items_page( delta, label1, label2 )
            link_html( less_link( delta ), label1, :class => 'less' ) + per_page.to_s + link_html( more_link( delta ), label2, :class => 'more' ) + " out of " + count.to_s
        end

        def close_page() '</div>' end

        # generate link html
        def link_html( link, label, opts={} ) %Q[<a href="#{link}" title="help" class="#{opts[:class]}">#{label}</a>] end

        # returns page number link html from an array of links; page is the
        # current page number.
        def page_number_link_html( links, page )
            return '' if links.empty?
            link_html = ''
            links.each_with_index { |l,i| link_html << '<a href="' + l +'" title="help" class="page_number">' + (page+i+1).to_s + '</a>' }
            return link_html
        end

    end
end  # SDN::Mixins::Pagination
