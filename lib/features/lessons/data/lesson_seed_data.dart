class LessonSeedData {
  LessonSeedData._();

  static const Map<String, List<Map<String, dynamic>>> byTopic = {
    'programming': [
      {
        'id': 'prog_01',
        'title': 'Variables and Data Types',
        'description': 'Understand how programs store and classify data.',
        'content': 'Variables are named containers for values. Data types define what kind of value can be stored, like int, double, String, and bool. Choosing the right type improves code clarity and prevents errors.',
        'keyConcepts': ['Variable declaration', 'Primitive data types', 'Type safety'],
        'examples': [
          'Create an int age = 18 and print it.',
          'Use String name = "Talbi" and combine it with another string.'
        ],
        'skill': 'Programming Basics',
        'difficulty': 'Beginner',
        'estimatedMinutes': 12,
        'order': 1,
        'tags': ['variables', 'types', 'fundamentals'],
        'targetLevels': ['Beginner']
      },
      {
        'id': 'prog_02',
        'title': 'Conditionals and Decisions',
        'description': 'Control the path of execution using conditions.',
        'content': 'Conditional statements let your program choose actions based on true or false checks. if/else blocks and switch statements are core decision-making tools in programming.',
        'keyConcepts': ['if/else', 'switch', 'Boolean logic'],
        'examples': [
          'If score >= 50, print Pass else print Retry.',
          'Use switch on menu choice to route user action.'
        ],
        'skill': 'Programming Basics',
        'difficulty': 'Beginner',
        'estimatedMinutes': 14,
        'order': 2,
        'tags': ['conditionals', 'boolean', 'logic'],
        'targetLevels': ['Beginner', 'Intermediate']
      },
      {
        'id': 'prog_03',
        'title': 'Functions and Reuse',
        'description': 'Write reusable blocks of code with parameters.',
        'content': 'Functions package logic into reusable units. They can take input parameters and return results, helping you avoid repeated code and making programs easier to maintain.',
        'keyConcepts': ['Function signature', 'Parameters', 'Return values'],
        'examples': [
          'Create add(a, b) that returns a + b.',
          'Refactor repeated print logic into one helper function.'
        ],
        'skill': 'Programming Basics',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 16,
        'order': 3,
        'tags': ['functions', 'abstraction', 'reuse'],
        'targetLevels': ['Beginner', 'Intermediate']
      }
    ],
    'algorithms': [
      {
        'id': 'algo_01',
        'title': 'Big O Intuition',
        'description': 'Compare algorithm efficiency in plain language.',
        'content': 'Big O describes how runtime or memory grows with input size. It helps you compare approaches before implementation and choose efficient solutions early.',
        'keyConcepts': ['Time complexity', 'Space complexity', 'Growth rates'],
        'examples': [
          'Linear search is O(n), binary search is O(log n).',
          'Nested loops often produce O(n^2) patterns.'
        ],
        'skill': 'Algorithms',
        'difficulty': 'Beginner',
        'estimatedMinutes': 15,
        'order': 1,
        'tags': ['big-o', 'analysis', 'performance'],
        'targetLevels': ['Beginner', 'Intermediate']
      },
      {
        'id': 'algo_02',
        'title': 'Sorting Strategies',
        'description': 'Understand the tradeoffs in common sorting methods.',
        'content': 'Sorting algorithms differ in speed, memory use, and implementation complexity. Knowing the tradeoffs lets you select the right algorithm for your constraints.',
        'keyConcepts': ['Stable vs unstable', 'Comparison sorts', 'Practical tradeoffs'],
        'examples': [
          'Merge sort gives predictable O(n log n).',
          'Insertion sort is efficient on nearly sorted small lists.'
        ],
        'skill': 'Algorithms',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 18,
        'order': 2,
        'tags': ['sorting', 'merge sort', 'insertion sort'],
        'targetLevels': ['Intermediate']
      },
      {
        'id': 'algo_03',
        'title': 'Recursion Foundations',
        'description': 'Solve problems by reducing them to smaller copies.',
        'content': 'Recursion solves a problem by calling the same function on a smaller input. Every recursive function needs a base case and a step that approaches it.',
        'keyConcepts': ['Base case', 'Recursive step', 'Call stack'],
        'examples': [
          'Factorial n! with n * factorial(n-1).',
          'Traverse a tree by recursively visiting child nodes.'
        ],
        'skill': 'Algorithms',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 20,
        'order': 3,
        'tags': ['recursion', 'trees', 'problem-solving'],
        'targetLevels': ['Intermediate', 'Advanced']
      }
    ],
    'data_structures': [
      {
        'id': 'ds_01',
        'title': 'Arrays vs Linked Lists',
        'description': 'Choose the right sequence structure for your data.',
        'content': 'Arrays store elements contiguously for fast indexing, while linked lists optimize insertion/removal in certain positions but have slower random access.',
        'keyConcepts': ['Indexing', 'Insertion cost', 'Memory layout'],
        'examples': [
          'Use arrays for frequent random access by index.',
          'Use linked lists when frequent inserts happen in the middle.'
        ],
        'skill': 'Data Structures',
        'difficulty': 'Beginner',
        'estimatedMinutes': 13,
        'order': 1,
        'tags': ['arrays', 'linked-list', 'tradeoffs'],
        'targetLevels': ['Beginner']
      },
      {
        'id': 'ds_02',
        'title': 'Stacks and Queues',
        'description': 'Model LIFO and FIFO behavior in real tasks.',
        'content': 'Stacks follow Last In First Out and queues follow First In First Out. They appear in parsers, undo systems, scheduling, and breadth/depth traversal patterns.',
        'keyConcepts': ['LIFO', 'FIFO', 'Push/Pop', 'Enqueue/Dequeue'],
        'examples': [
          'Undo operation stack in text editors.',
          'Queue for processing users in arrival order.'
        ],
        'skill': 'Data Structures',
        'difficulty': 'Beginner',
        'estimatedMinutes': 12,
        'order': 2,
        'tags': ['stack', 'queue', 'operations'],
        'targetLevels': ['Beginner', 'Intermediate']
      },
      {
        'id': 'ds_03',
        'title': 'Hash Tables Basics',
        'description': 'Store and retrieve key-value data efficiently.',
        'content': 'Hash tables map keys to array positions using a hash function. They provide fast average-case lookup, insert, and delete operations when collisions are handled well.',
        'keyConcepts': ['Hash function', 'Collisions', 'Load factor'],
        'examples': [
          'Use a map to count word frequencies quickly.',
          'Cache user preferences by user ID.'
        ],
        'skill': 'Data Structures',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 17,
        'order': 3,
        'tags': ['hash-table', 'maps', 'lookup'],
        'targetLevels': ['Intermediate']
      }
    ],
    'databases': [
      {
        'id': 'db_01',
        'title': 'Relational Model Essentials',
        'description': 'Learn tables, rows, keys, and relationships.',
        'content': 'Relational databases organize data into tables. Primary keys uniquely identify rows, while foreign keys create links between related tables.',
        'keyConcepts': ['Tables', 'Primary key', 'Foreign key', 'Relations'],
        'examples': [
          'Students table linked to Courses table through enrollment.',
          'Use primary key id for unique row access.'
        ],
        'skill': 'Databases',
        'difficulty': 'Beginner',
        'estimatedMinutes': 14,
        'order': 1,
        'tags': ['relational', 'keys', 'schema'],
        'targetLevels': ['Beginner']
      },
      {
        'id': 'db_02',
        'title': 'SELECT and Filtering',
        'description': 'Query only the data you need with SQL.',
        'content': 'SELECT retrieves data from tables. WHERE filters records, ORDER BY sorts results, and LIMIT constrains output size for efficient reads.',
        'keyConcepts': ['SELECT', 'WHERE', 'ORDER BY', 'LIMIT'],
        'examples': [
          'Find students with score > 80.',
          'Sort products by price descending.'
        ],
        'skill': 'Databases',
        'difficulty': 'Beginner',
        'estimatedMinutes': 12,
        'order': 2,
        'tags': ['sql', 'query', 'filter'],
        'targetLevels': ['Beginner', 'Intermediate']
      },
      {
        'id': 'db_03',
        'title': 'JOINs Without Fear',
        'description': 'Combine data from multiple related tables.',
        'content': 'JOIN statements merge rows from two or more tables using related columns. INNER JOIN returns matching rows, while LEFT JOIN keeps all left-side rows.',
        'keyConcepts': ['INNER JOIN', 'LEFT JOIN', 'Join keys'],
        'examples': [
          'Join orders with customers to display customer names.',
          'Left join users with activity to include inactive users.'
        ],
        'skill': 'Databases',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 19,
        'order': 3,
        'tags': ['joins', 'sql', 'relationships'],
        'targetLevels': ['Intermediate', 'Advanced']
      }
    ],
    'web': [
      {
        'id': 'web_01',
        'title': 'HTML Structure Basics',
        'description': 'Build semantic page structure the right way.',
        'content': 'HTML defines page structure. Semantic tags like header, main, section, and footer improve readability, SEO, and accessibility.',
        'keyConcepts': ['Semantic HTML', 'Document structure', 'Accessibility'],
        'examples': [
          'Use main for core content and nav for navigation links.',
          'Add alt text to images for screen readers.'
        ],
        'skill': 'Web Basics',
        'difficulty': 'Beginner',
        'estimatedMinutes': 11,
        'order': 1,
        'tags': ['html', 'semantic', 'web'],
        'targetLevels': ['Beginner']
      },
      {
        'id': 'web_02',
        'title': 'CSS Layout with Flexbox',
        'description': 'Create responsive one-dimensional layouts.',
        'content': 'Flexbox aligns and distributes items in rows or columns. It helps create adaptive layouts with minimal CSS and fewer media-query hacks.',
        'keyConcepts': ['Flex container', 'Alignment', 'Spacing'],
        'examples': [
          'Center a card both vertically and horizontally.',
          'Distribute nav links with space-between.'
        ],
        'skill': 'Web Basics',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 16,
        'order': 2,
        'tags': ['css', 'flexbox', 'layout'],
        'targetLevels': ['Beginner', 'Intermediate']
      },
      {
        'id': 'web_03',
        'title': 'JavaScript Async Concepts',
        'description': 'Handle asynchronous operations with confidence.',
        'content': 'Async programming prevents UI blocking while waiting for operations like API calls. Promises and async/await make this flow easier to read and maintain.',
        'keyConcepts': ['Promise', 'async/await', 'Event loop'],
        'examples': [
          'Fetch user profile and render once data arrives.',
          'Show loading state while waiting for response.'
        ],
        'skill': 'Web Basics',
        'difficulty': 'Intermediate',
        'estimatedMinutes': 18,
        'order': 3,
        'tags': ['javascript', 'async', 'api'],
        'targetLevels': ['Intermediate', 'Advanced']
      }
    ],
  };
}
