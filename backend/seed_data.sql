-- ============================================================
-- Seed data: learning fields + a starter set of materials.
-- Run AFTER schema.sql:
--   mysql -u root -p lms_db < seed_data.sql
--
-- Feel free to add more rows to `materials` any time — the app
-- reads whatever is in this table, nothing is hardcoded in code.
-- ============================================================

USE lms_db;

INSERT INTO fields (slug, label, icon) VALUES
    ('developer',     'Developer',      '💻'),
    ('devops',        'DevOps',         '⚙️'),
    ('cybersecurity', 'Cybersecurity',  '🛡️'),
    ('linux',         'Linux',          '🐧'),
    ('cloud',         'Cloud Computing','☁️')
ON DUPLICATE KEY UPDATE label = VALUES(label);

INSERT INTO materials (field_slug, title, url, resource_type, platform, description) VALUES
-- Developer
('developer', 'CS50: Introduction to Computer Science', 'https://www.youtube.com/playlist?list=PLhQjrBD2T382_R182iC2gNZI9HzWFMC_8', 'video', 'YouTube / Harvard', 'Harvard''s famous intro to CS and programming fundamentals.'),
('developer', 'The Odin Project', 'https://www.theodinproject.com/', 'course', 'The Odin Project', 'Free full-stack web development curriculum, project-based.'),
('developer', 'freeCodeCamp', 'https://www.freecodecamp.org/', 'course', 'freeCodeCamp', 'Hands-on certifications covering web dev, JS, Python, and more.'),

-- DevOps
('devops', 'Docker Tutorial for Beginners', 'https://www.youtube.com/watch?v=3c-iBn73dDE', 'video', 'YouTube / TechWorld with Nana', 'A complete beginner walkthrough of Docker fundamentals.'),
('devops', 'Kubernetes Course for Beginners', 'https://www.youtube.com/watch?v=X48VuDVv0do', 'video', 'YouTube / TechWorld with Nana', 'Full Kubernetes crash course covering core concepts.'),
('devops', 'Play with Docker', 'https://labs.play-with-docker.com/', 'course', 'Play with Docker', 'Free browser-based Docker playground, no install required.'),
('devops', 'Killercoda Scenarios', 'https://killercoda.com/', 'course', 'Killercoda', 'Interactive, browser-based DevOps/K8s/Linux scenarios.'),
('devops', 'The DevOps Roadmap', 'https://roadmap.sh/devops', 'article', 'roadmap.sh', 'Visual, step-by-step roadmap for learning DevOps.'),

-- Cybersecurity
('cybersecurity', 'Cybersecurity Full Course for Beginners', 'https://www.youtube.com/watch?v=U_P23SqJaDc', 'video', 'YouTube / freeCodeCamp', 'A ground-up introduction to cybersecurity concepts.'),
('cybersecurity', 'TryHackMe', 'https://tryhackme.com/', 'course', 'TryHackMe', 'Guided, hands-on security labs for all skill levels.'),
('cybersecurity', 'OWASP Top 10', 'https://owasp.org/www-project-top-ten/', 'docs', 'OWASP', 'The industry-standard list of critical web app security risks.'),

-- Linux
('linux', 'Linux Command Line for Beginners', 'https://www.youtube.com/watch?v=IVquJh3DXUA', 'video', 'YouTube / freeCodeCamp', 'Full course on using the Linux terminal.'),
('linux', 'Linux Journey', 'https://linuxjourney.com/', 'course', 'Linux Journey', 'Bite-sized, free lessons covering Linux from the ground up.'),
('linux', 'The Linux Documentation Project', 'https://tldp.org/', 'docs', 'TLDP', 'Long-standing reference documentation for Linux.'),

-- Cloud
('cloud', 'AWS Cloud Practitioner Essentials', 'https://www.youtube.com/watch?v=SOTamWNgDKc', 'video', 'YouTube / freeCodeCamp', 'Full course covering AWS fundamentals for the CCP exam.'),
('cloud', 'Microsoft Learn: Azure Fundamentals', 'https://learn.microsoft.com/en-us/training/paths/azure-fundamentals/', 'course', 'Microsoft Learn', 'Free, structured Azure fundamentals learning path.');
