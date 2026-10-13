.pragma library

// Motivational quotes shown in the Calendar header when the quote API has not answered yet (or
// offline). QuoteService prefers fresh API quotes and falls back to these, so the header is
// never empty.
var fallback = [
    { q: "The secret of getting ahead is getting started.", a: "Mark Twain" },
    { q: "It does not matter how slowly you go as long as you do not stop.", a: "Confucius" },
    { q: "Well done is better than well said.", a: "Benjamin Franklin" },
    { q: "The best way to predict the future is to create it.", a: "Peter Drucker" },
    { q: "You miss 100% of the shots you don't take.", a: "Wayne Gretzky" },
    { q: "Whether you think you can, or you think you can't, you're right.", a: "Henry Ford" },
    { q: "The journey of a thousand miles begins with a single step.", a: "Lao Tzu" },
    { q: "What we think, we become.", a: "Buddha" },
    { q: "Act as if what you do makes a difference. It does.", a: "William James" },
    { q: "Do what you can, with what you have, where you are.", a: "Theodore Roosevelt" },
    { q: "It always seems impossible until it's done.", a: "Nelson Mandela" },
    { q: "Courage is not the absence of fear, but the triumph over it.", a: "Nelson Mandela" },
    { q: "Everything you've ever wanted is on the other side of fear.", a: "George Addair" },
    { q: "Dream big and dare to fail.", a: "Norman Vaughan" },
    { q: "Small deeds done are better than great deeds planned.", a: "Peter Marshall" },
    { q: "Start where you are. Use what you have. Do what you can.", a: "Arthur Ashe" },
    { q: "Believe you can and you're halfway there.", a: "Theodore Roosevelt" },
    { q: "The only way to do great work is to love what you do.", a: "Steve Jobs" },
    { q: "Fall seven times, stand up eight.", a: "Japanese proverb" },
    { q: "Energy and persistence conquer all things.", a: "Benjamin Franklin" },
    { q: "Don't watch the clock; do what it does. Keep going.", a: "Sam Levenson" },
    { q: "A year from now you may wish you had started today.", a: "Karen Lamb" },
    { q: "Nothing will work unless you do.", a: "Maya Angelou" },
    { q: "Perseverance is not a long race; it is many short races one after the other.", a: "Walter Elliot" },
    { q: "Success is the sum of small efforts, repeated day in and day out.", a: "Robert Collier" },
    { q: "The harder I work, the luckier I get.", a: "Samuel Goldwyn" },
    { q: "Quality is not an act, it is a habit.", a: "Aristotle" },
    { q: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", a: "Will Durant" },
    { q: "No one can make you feel inferior without your consent.", a: "Eleanor Roosevelt" },
    { q: "Do one thing every day that scares you.", a: "Eleanor Roosevelt" },
    { q: "The future depends on what you do today.", a: "Mahatma Gandhi" },
    { q: "Be the change that you wish to see in the world.", a: "Mahatma Gandhi" },
    { q: "In the middle of difficulty lies opportunity.", a: "Albert Einstein" },
    { q: "Hard choices, easy life. Easy choices, hard life.", a: "Jerzy Gregorek" },
    { q: "Discipline is the bridge between goals and accomplishment.", a: "Jim Rohn" },
    { q: "What you do today can improve all your tomorrows.", a: "Ralph Marston" },
    { q: "Make each day your masterpiece.", a: "John Wooden" },
    { q: "Don't count the days, make the days count.", a: "Muhammad Ali" },
    { q: "Great things are done by a series of small things brought together.", a: "Vincent van Gogh" },
    { q: "The expert in anything was once a beginner.", a: "Helen Hayes" }
]

// The API answers with { q, a }. A rate-limited call still returns HTTP 200 with a pseudo-quote
// credited to "zenquotes.io", so anything like that is rejected.
function clean(entry) {
    if (!entry || typeof entry.q !== "string" || typeof entry.a !== "string") return null
    var text = entry.q.replace(/\s+/g, " ").trim()
    var author = entry.a.replace(/\s+/g, " ").trim()
    if (text.length < 8 || text.length > 320) return null
    if (author.toLowerCase() === "zenquotes.io" || /^too many requests/i.test(text)) return null
    return { q: text, a: author }
}

function parse(json) {
    var list = JSON.parse(json)
    if (!Array.isArray(list)) return []
    var out = []
    for (var i = 0; i < list.length; i++) {
        var entry = clean(list[i])
        if (entry) out.push(entry)
    }
    return out
}
