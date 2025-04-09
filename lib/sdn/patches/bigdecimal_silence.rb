# OK, so some stupid ass dipshit fuckface retard decided to deprecate
# BigDecimal.new in favor of BigDecimal, which throws up a depcrecated warning
# every time a DataMapper Resource instantiates individual Decimal properties.
# For large collections, this is *a lot*.
#
# The setup: at the time BigDecimal was introduced, all the other numerics were
# built-in types, but BigDecimal was an add-on.  The original author followed
# normal class semantics (using .new) instead of mimicking the other numerics
# (no .new).  So someone super Bright and Probably Loved by All (*****NOT*****)
# decided to Fix It.  Asshole!
#
# The problem manifests for us because BigDecimal.new is actually invoked inside
# the data_objects individual adapters -- which are in C.  dm-core passes in the
# query, the fields/properties (Decimals in our case) and the expected
# Ruby-native types (BigDecimals in our case) -- and calls .new on them.  Boom,
# one warning per Decimal field for every Resource.
#
# The Proper fix is to update the DO drivers, which we can do later.  For now,
# fuck that stupid warning.

def BigDecimal.new(*args, **kwargs)
    BigDecimal(*args, **kwargs)
end
