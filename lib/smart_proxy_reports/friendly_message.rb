class FriendlyMessage
  def initialize(result)
    @result = result
    @result_tree = @result["result"]
    @task_tree = @result["task"]
    @module_args_tree = @result_tree.dig("invocation", "module_args")
  end

  def generate_message
    msg = "N/A"
    return msg if @task_tree.nil? || @task_tree["action"].nil?
    return @result_tree["msg"] if @result["failed"]

    case @task_tree["action"]
    when "ansible.builtin.assemble", "assemble" then msg = assemble_message
    when "ansible.builtin.dnf", "dnf" then msg = dnf_message
    when "ansible.builtin.git", "git" then msg = git_message
    when "ansible.builtin.file", "file" then msg = file_message
    when "ansible.builtin.package", "package" then msg = package_message
    when "ansible.builtin.systemd", "systemd" then msg = systemd_message
    when "ansible.builtin.tempfile", "tempfile" then msg = tempfile_message
    when "ansible.builtin.known_hosts", "known_hosts" then msg = known_hosts_message
    when "ansible.builtin.pip", "pip" then msg = pip_message
    when "ansible.builtin.template", "template" then msg = template_message
    when "ansible.builtin.service", "service" then msg = service_message
    when "ansible.builtin.unarchive", "unarchive" then msg = unarchive_message
    when "ansible.builtin.group", "group" then msg = group_message
    when "ansible.builtin.user", "user" then msg = user_message
    when "ansible.builtin.cron", "cron" then msg = cron_message
    when "ansible.builtin.copy", "copy" then msg = copy_message
    when "ansible.posix.authorized_key", "authorized_key" then msg = authorized_key_message
    when "ansible.posix.acl", "acl" then msg = @result_tree["msg"]
    when "ansible.posix.at", "at" then msg = at_message
    when "ansible.posix.firewalld", "firewalld" then msg = @result_tree["msg"]
    when "ansible.posix.mount", "mount" then msg = mount_message
    when "ansible.posix.seboolean", "seboolean" then msg = seboolean_message
    when "ansible.posix.selinux", "selinux" then msg = @result_tree["msg"]
    when "ansible.posix.sysctl", "sysctl" then msg = sysctl_message
    when "ansible.posix.patch", "patch" then msg = patch_message
    when "ansible.builtin.command", "ansible.builtin.shell", "command", "shell" then msg = @result_tree["stdout_lines"]
    end
    msg
  rescue StandardError => e
    logger.debug "Unable to parse result (#{e.message}): #{@result.inspect}"
    msg
  end

  def assemble_message
    "Concatenation of #{@result_tree["src"]} into #{@result_tree["dest"]}"
  end

  def dnf_message
    package_message
  end

  def git_message
    if @module_args_tree["clone"]
      return "Repository #{@module_args_tree["repo"]} cloned into #{@module_args_tree["dest"]}"
    end
    "Check if clone of #{@module_args_tree["repo"]} exists"
  end

  def human_readable_array(array, length = 10)
    return array if array.nil?
    return array.slice(0, length).join(", ") + " and more" if array.length > length
    array.join(", ")
  end

  def file_message
    changes = []
    unless @module_args_tree["follow"] then changes << "follow" end
    if @module_args_tree["state"] != "file" then changes << "state" end
    ["access_time_format", "modification_time_format"].each do |format|
      if @module_args_tree[format] != "%Y%m%d%H%M.%S" then changes << format end
    end
    ["force", "recurse", "unsafe_writes"].each do |default|
      if @module_args_tree[default] then changes << default end
    end
    ["access_time", "attributes", "group", "mode", "modification_time", "owner", "selevel", "serole", "setype", "seuser", "src"].each do |i|
      unless @module_args_tree[i].nil? then changes << i end
    end
    file = @module_args_tree["path"]
    "#{file} attributes changed: #{human_readable_array(changes)}"
  end

  def package_message
    packages = human_readable_array(@module_args_tree["name"])
    state = "present"
    state = @module_args_tree["state"] unless @module_args_tree["state"].nil?
    "Package(s) #{packages} are #{state}"
  end

  def known_hosts_message
    "#{@module_args_tree["name"]} is #{@module_args_tree["state"]} in #{@module_args_tree["path"]}"
  end

  def pip_message
    packages = human_readable_array(@module_args_tree["name"]) || "contained in #{@module_args_tree["requirements"]}"
    "Package(s) #{packages} are #{@module_args_tree["state"]}"
  end

  def systemd_message
    "Service #{@module_args_tree["name"]} #{@module_args_tree["state"]}"
  end

  def tempfile_message
    "Temporary #{@result_tree["state"]} created: #{@result_tree["path"]}"
  end

  def template_message
    "Render template #{@module_args_tree["_original_basename"]} to #{@result_tree["dest"]}"
  end

  def service_message
    "Service #{@result_tree["name"]} is #{@result_tree["state"]} and enabled: #{@result_tree["enabled"]}"
  end

  def unarchive_message
    "Archive #{@module_args_tree["src"]} unpacked into #{@module_args_tree["dest"]}"
  end

  def group_message
    "User group #{@result_tree["name"]} is #{@result_tree["state"]} with gid: #{@result_tree["gid"]}"
  end

  def user_message
    "User #{@result_tree["name"]} is #{@result_tree["state"]} with uid: #{@result_tree["uid"]}"
  end

  def cron_message
    "Cron job: #{@module_args_tree["minute"]} #{@module_args_tree["hour"]} #{@module_args_tree["day"]} #{@module_args_tree["month"]} #{@module_args_tree["weekday"]} #{@module_args_tree["job"]} and disabled: #{@module_args_tree["disabled"]}"
  end

  def copy_message
    "Copy #{@module_args_tree["_original_basename"]} to #{@result_tree["dest"]}"
  end

  def authorized_key_message
    "Key #{@module_args_tree["key"]} #{@module_args_tree["state"]} for user #{@module_args_tree["user"]}"
  end

  def at_message
    time = ""
    to_exec = @module_args_tree["script_file"] || @module_args_tree["command"]
    if @module_args_tree["count"] && @module_args_tree["units"] then time = " in #{@module_args_tree["count"]} #{@module_args_tree["units"]}" end
    if @module_args_tree["count"] && @module_args_tree["units"] then verb = "will be " else verb = "is " end
    state = verb + @module_args_tree["state"]
    "#{to_exec} #{state}#{time}"
  end

  def mount_message
    path = @module_args_tree["path"] || @module_args_tree["name"]
    if @module_args_tree["backup"] then backup = "backup created" else backup = "no backup" end
    message = "Mountpoint #{path} #{@module_args_tree["state"]}, #{backup}"
    if @module_args_tree["boot"] then message += ", mounted on boot" end
    message
  end

  def seboolean_message
    if @module_args_tree["state"] then state = "on" else state = "off" end
    if @module_args_tree["persistent"] then persistent = "" else persistent = "do not" end
    persistent += "keep it persistent across reboots"
    "Set #{@module_args_tree["name"]} flag #{state}, #{persistent}"
  end

  def sysctl_message
    value = @module_args_tree["value"] || @module_args_tree["val"]
    if value == "" then value = "" else value = " to " + value end
    present = @module_args_tree["state"] == "present"
    if present then action, path = "Set", "in " else action, path = "Remove", "from " end
    path += @module_args_tree["sysctl_file"]
    if @module_args_tree["sysctl_set"] then sys_set = ", verify token value with the sysctl command" else sys_set = "" end
    if @module_args_tree["ignoreerrors"] then ignore = ", errors ignored" else ignore = "" end
    "#{action} #{@module_args_tree["name"]}#{value} #{path}#{sys_set}#{ignore}"
  end

  def patch_message
    src = @module_args_tree["src"] || @module_args_tree["patchfile"]
    if @module_args_tree["remote_src"] then src += " (from remote machine)" end
    if @module_args_tree["state"] == "present" then action = "Apply" else action = "Revert" end
    if @module_args_tree["basedir"] then basedir = ", applied in #{@module_args_tree["basedir"]}" else basedir = "" end
    if @module_args_tree["dest"] then dest = ", file #{@module_args_tree["dest"]} to be patched" else dest = "" end
    if @module_args_tree["backup"] then backup = ", backup produced" else backup = "" end
    "#{action} patch #{src}#{basedir}#{dest}#{backup}"
  end
end
