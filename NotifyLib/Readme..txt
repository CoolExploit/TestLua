📘 Notification Library Docs
Made by CoolExploit

This is a simple, clean notification system with support for smooth animations, icons, timers, and stacking. Super easy to use. No bloat.

📦 Load the Library
lua
Copy
Edit
local NotifyLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/CoolExploit/TestLua/refs/heads/main/NotifyLib/NotificationLib.txt"))()
🚀 Usage
lua
Copy
Edit
NotifyLib:Notify({
    Title = "Script Ready!",
    Content = "You may now use your tools.",
    Time = 4,
    Image = "rbxassetid://115523122240350" -- optional
})
🧠 Parameters
Property	Type	Description
Title	string	The main title text (bold, larger)
Content	string	The subtext or description
Time	number	Duration in seconds before it fades
Image	string	Optional image ID (like "rbxassetid://123456") — default image used if not set
🔄 If you don’t provide an Image, it will automatically use this default icon:
rbxassetid://115523122240350

If you want it to show nothing, set Image = "".

💡 Example: No Image
lua
Copy
Edit
NotifyLib:Notify({
    Title = "No Icon!",
    Content = "This one uses the default image.",
    Time = 3
})
💡 Example: Custom Image
lua
Copy
Edit
NotifyLib:Notify({
    Title = "Cool Alert",
    Content = "You set your own icon.",
    Time = 5,
    Image = "rbxassetid://12345678"
})
📚 Extra Features
✅ Stacking: Multiple notifications stack up smoothly
✅ Auto-removal: Fades out after the given Time
✅ Tweened UI: Clean sliding + timer bar animation
✅ Black theme: Sleek and modern look
✅ Modular: Works like a library — can be reused in any script

👨‍💻 Want to Customize It?
Feel free to fork it, edit the theme, add your own icon style, sounds, etc. It’s all open and editable.

❓Having Issues?
Make sure:

You're not using this in a locked environment like CoreGui
Your executor supports loadstring and HTTP requests
Your Image ID is correct and uploaded properly
