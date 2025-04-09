# Utils are the common library of utility classes and core object extensions
# which will be available to all CC application environments by default.
#
# We force-load active-support's core extensions first, so ours will always win.
#
# [jpr5 10/11/11] And we have to load readline before AS's core_ext, otherwise
# loading ruby-debug after AS core_ext will throw an RbReadline::Encoding
# related exception (read: Rails people are complete fuckwit numbnuts who have
# stolen so much of my life from me AND I WANT IT FUCKING BACK FUCKERS!!!!!)
require 'readline'
require 'active_support/core_ext'

require 'sdn/utils/object'
Dir["#{File.dirname(__FILE__)}/utils/*.rb"].sort.each { |f| require f }
