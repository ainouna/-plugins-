-- The Tuxbox Copyright
--
-- Copyright 2018 Markus Volk, Sven Hoefer, Don de Deckelwech
-- Changes for Boxmode 12 by BPanther 17/Mar/2019
--
-- Redistribution and use in source and binary forms, with or without modification, 
-- are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this list
-- of conditions and the following disclaimer. Redistributions in binary form must
-- reproduce the above copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS`` AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of the Tuxbox Project.

caption = "STB-Startup"

n = neutrino()
fh = filehelpers.new()

devbase = "/dev/mmcblk0p"
bootfile = "/boot/STARTUP"

for line in io.lines(bootfile) do
	i, j = string.find(line, devbase)
	bm = string.find(line, "boxmode")
	current_root = tonumber(string.sub(line,j+1,j+2))
	current_boxmode = string.sub(line,bm)
end

locale = {}

locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus.",
	start_partition = "Auf die gewählte Partition umschalten ?",
	reboot_partition = "Jetzt neustarten ?",
	empty_partition = "Die gewählte Partition ist leer !"
}

locale["english"] = {
	current_boot_partition = "The current boot partition is: ",
	choose_partition = "\n\nPlease choose the new boot partition.",
	start_partition = "Switch to the choosen partition ?",
	reboot_partition = "Reboot now ?",
	empty_partition = "The selected partition is empty !"
}

function sleep (a)
	local sec = tonumber(os.clock() + a);
	while (os.clock() < sec) do
	end
end

function reboot()
	local file = assert(io.popen("which systemctl >> /dev/null"))
	running_init = file:read('*line')
	file:close()
	if running_init == "/bin/systemctl" then
		local file = assert(io.popen("systemctl reboot"))
	else
		local file = assert(io.popen("sync && init 6"))
	end
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function get_imagename(root, boxmode)
	imagename = ""
	local glob = require "posix".glob
	for _, j in pairs(glob('/boot/*', 0)) do
		for line in io.lines(j) do
			if (j ~= bootfile) then
				if line:match(devbase .. root) then
					if line:match(boxmode) then
						imagename = basename(j)
					end
				end
			end
		end
	end
	return imagename
end

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end
timing_menu = neutrino_conf:getString("timing.menu", "0")

cdx = 700;

if (get_imagename(3, "boxmode=12'")) then
	btn_6 = get_imagename(3, "boxmode=12'")
	if (not (btn_6 == "")) then
		cdx = cdx + 118
	end
end
if (get_imagename(5, "boxmode=12'")) then
	btn_7 = get_imagename(5, "boxmode=12'")
	if (not (btn_7 == "")) then
		cdx = cdx + 118
	end
end
if (get_imagename(7, "boxmode=12'")) then
	btn_8 = get_imagename(7, "boxmode=12'")
	if (not (btn_8 == "")) then
		cdx = cdx + 118
	end
end
if (get_imagename(9, "boxmode=12'")) then
	btn_9 = get_imagename(9, "boxmode=12'")
	if (not (btn_9 == "")) then
		cdx = cdx + 118
	end
end

chooser_dx = n:scale2Res(cdx)
chooser_dy = n:scale2Res(200)
chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

chooser = cwindow.new {
	x = chooser_x,
	y = chooser_y,
	dx = chooser_dx,
	dy = chooser_dy,
	title = caption,
	icon = "settings",
	has_shadow = true,
	btnRed = get_imagename(3, "boxmode=1'"),
	btnGreen = get_imagename(5, "boxmode=1'"),
	btnYellow = get_imagename(7, "boxmode=1'"),
	btnBlue = get_imagename(9, "boxmode=1'"),
	btn6 = btn_6,
	btn7 = btn_7,
	btn8 = btn_8,
	btn9 = btn_9
}

chooser_text = ctext.new {
	parent = chooser,
	x = OFFSET.INNER_MID,
	y = OFFSET.INNER_SMALL,
	dx = chooser_dx - 2*OFFSET.INNER_MID,
	dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
	text = locale[lang].current_boot_partition .. get_imagename(current_root, current_boxmode) .. locale[lang].choose_partition,
	font_text = FONT.MENU,
	mode = "ALIGN_CENTER"
}

chooser:paint()

i = 0
d = 500 -- ms
t = (timing_menu * 1000) / d
if t == 0 then
	t = -1 -- no timeout
end

colorkey = nil
repeat
	i = i + 1
	msg, data = n:GetInput(d)
	if (msg == RC['red']) then
		root = 3
		box_mode = "boxmode=1'"
		colorkey = true
	elseif (msg == RC['green']) then
		root = 5
		box_mode = "boxmode=1'"
		colorkey = true
	elseif (msg == RC['yellow']) then
		root = 7
		box_mode = "boxmode=1'"
		colorkey = true
	elseif (msg == RC['blue']) then
		root = 9
		box_mode = "boxmode=1'"
		colorkey = true
	elseif (msg == RC['6']) then
		root = 3
		box_mode = "boxmode=12'"
		colorkey = true
	elseif (msg == RC['7']) then
		root = 5
		box_mode = "boxmode=12'"
		colorkey = true
	elseif (msg == RC['8']) then
		root = 7
		box_mode = "boxmode=12'"
		colorkey = true
	elseif (msg == RC['9']) then
		root = 9
		box_mode = "boxmode=12'"
		colorkey = true
	end
until msg == RC['home'] or colorkey or i == t

chooser:hide()

if colorkey then
	local file = assert(io.popen("blkid " .. devbase .. root .. " | grep TYPE"))
	local check_exist = file:read('*line')
	file:close()
	if (check_exist == nil) then
		c = 1
	else
		local file = assert(io.popen("cat /proc/mounts | grep " .. devbase .. root .. " | awk -F ' ' '{print $2}'"))
		local mounted_part = file:read('*line')
		file:close()
		if(mounted_part == nil) then
			mounted_part = ''
		end
		a,b,c = os.execute("test -d " .. mounted_part .. "/usr")
	end
	if (c == 1) then
		local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].empty_partition };
		ret:paint();
		sleep(3)
		return
	else
		res = messagebox.exec {
			title = caption,
			icon = "settings",
			text = locale[lang].start_partition,
			timeout = 0,
			buttons={ "yes", "no" },
			--default = "no"
		}
	end
end

if res == "yes" then
	local glob = require "posix".glob
	for _, j in pairs(glob('/boot/*', 0)) do
		for line in io.lines(j) do
			if line:match(devbase .. root) then
				if line:match(box_mode) then
					if (j ~= bootfile) then
						local file = io.open(bootfile, "w")
						file:write(line .. "\n")
						file:close()
					end
				end
			end
		end
	end
	res = messagebox.exec {
		title = caption,
		icon = "settings",
		text = locale[lang].reboot_partition,
		timeout = 0,
		buttons={ "yes", "no" },
		--default = "no"
	}
	if res == "yes" then
		reboot()
	end
end

return
