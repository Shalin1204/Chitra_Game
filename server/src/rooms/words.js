const WORD_CATEGORIES = [
  { category: 'Animals', words: ['cat', 'dog', 'elephant', 'frog', 'lion', 'monkey', 'zebra', 'kangaroo', 'turtle', 'unicorn', 'whale'] },
  { category: 'Objects', words: ['guitar', 'house', 'igloo', 'kite', 'piano', 'umbrella', 'violin', 'bicycle', 'car', 'door'] },
  { category: 'Food / Eating Thing', words: ['apple', 'banana', 'hamburger', 'lemon', 'pizza', 'sushi', 'taco', 'pancake', 'cookie'] },
  { category: 'Nature', words: ['jungle', 'ocean', 'sun', 'tree', 'water', 'flower', 'mountain', 'island'] },
  { category: 'Trending Movie Character', words: ['Batman', 'Spider-Man', 'Iron Man', 'Joker', 'Superman', 'Deadpool', 'Wolverine', 'Harry Potter'] },
  { category: 'Mythical / Sci-Fi', words: ['ghost', 'ninja', 'robot', 'vampire', 'alien', 'zombie', 'wizard', 'dragon'] }
];

function getRandomWords(count = 3) {
  // Flatten all words into an array of { word, category }
  const allChoices = [];
  for (const group of WORD_CATEGORIES) {
    for (const word of group.words) {
      allChoices.push({ word, category: group.category });
    }
  }
  
  // Shuffle and pick
  const shuffled = [...allChoices].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

module.exports = { WORD_CATEGORIES, getRandomWords };
