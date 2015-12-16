# You might need these
# require 'pathname'
# require 'fileutils'

# In case we want to also print the already updated plug-ins
DISPLAY_ALREADY_UPDATED = false

# Change our path
plugin_path = ARGV[0]
# This path needs to escape the backslash
escaped_plugin_path = plugin_path.gsub('Application Support', 'Application\ Support')

# Exit if the folder is not there
unless Dir.exists? plugin_path
	puts "The plugin folder doesn't exist at the required path."
	exit
end

files = Dir.entries(plugin_path).select { |f| f["xcplugin"] != nil }

# Exit if there are no plugins
if files.none?
	puts "You have no plugins..."
	exit
end

# Keep track of these for a nice output message
updated_plugins  = 0
uptodate_plugins = 0

# Iterate through all plugins
files.each do |plugin|
	# Lazy, lazy :)
	xcode_uuid_key    = 'DVTPlugInCompatibilityUUID'
	plugin_uuids_key  = xcode_uuid_key + 's'
	plugin_plist      = "#{escaped_plugin_path}#{plugin}/Contents/Info.plist"
	plugin_uuids      = `defaults read #{plugin_plist} #{plugin_uuids_key}`
	latest_xcode_uuid = `defaults read /Applications/Xcode.app/Contents/Info #{xcode_uuid_key}`.gsub! "\n", ''

	# If the value is already there, skip and optionally notify
	if plugin_uuids.include? latest_xcode_uuid
		uptodate_plugins += 1
		next
	end

	system "defaults write #{plugin_plist} #{plugin_uuids_key} -array-add #{latest_xcode_uuid}"

	updated_plugins += 1
end

puts "#{updated_plugins}, #{uptodate_plugins}"
