/// Legal document texts shown in [LegalPage].
///
/// NOTE: This is template text for the Futsal Zadar app. It should be
/// reviewed (and if needed replaced) by the organization's legal counsel
/// before store release.
library;

const String kTermsOfServiceText = '''
UVJETI KORIŠTENJA

Zadnja izmjena: 22. srpnja 2026.

1. OPĆENITO

Ovi Uvjeti korištenja ("Uvjeti") uređuju korištenje mobilne aplikacije Futsal Zadar ("Aplikacija"). Preuzimanjem, instaliranjem ili korištenjem Aplikacije prihvaćate ove Uvjete u cijelosti. Ako se ne slažete s Uvjetima, nemojte koristiti Aplikaciju.

2. NAMJENA APLIKACIJE

Aplikacija pruža informacije o malonogometnim ligama i turnirima u organizaciji Futsal Zadra: rasporede i rezultate utakmica, tablice, statistike igrača, vijesti i obavijesti. Sadržaj je informativnog karaktera.

3. KORIŠTENJE APLIKACIJE

Aplikaciju smijete koristiti isključivo u osobne, nekomercijalne svrhe. Zabranjeno je:
• kopiranje, distribucija ili izmjena sadržaja Aplikacije bez prethodnog odobrenja;
• korištenje Aplikacije na način koji bi mogao onemogućiti ili otežati njezin rad;
• pokušaj neovlaštenog pristupa sustavima ili podacima povezanima s Aplikacijom.

4. TOČNOST PODATAKA

Ulažemo razuman trud da podaci u Aplikaciji (rezultati, rasporedi, statistike) budu točni i ažurni, ali ne jamčimo njihovu potpunost ni točnost. Službeni rezultati i odluke objavljuju se putem službenih kanala organizatora natjecanja.

5. OBAVIJESTI

Aplikacija može slati push obavijesti (npr. o golovima, početku utakmica i novim vijestima). Obavijesti možete onemogućiti u postavkama svog uređaja.

6. INTELEKTUALNO VLASNIŠTVO

Svi žigovi, logotipi, grafike i sadržaji u Aplikaciji vlasništvo su organizatora natjecanja ili njihovih partnera te su zaštićeni propisima o intelektualnom vlasništvu.

7. OGRANIČENJE ODGOVORNOSTI

Aplikacija se pruža "kakva jest". U najvećoj mjeri dopuštenoj zakonom, ne odgovaramo za štetu nastalu korištenjem ili nemogućnošću korištenja Aplikacije, uključujući štetu nastalu zbog netočnih ili nepotpunih podataka.

8. IZMJENE UVJETA

Zadržavamo pravo izmjene ovih Uvjeta. O bitnim izmjenama obavijestit ćemo vas putem Aplikacije. Nastavkom korištenja Aplikacije nakon izmjena prihvaćate izmijenjene Uvjete.

9. KONTAKT

Za sva pitanja u vezi ovih Uvjeta možete nas kontaktirati putem službenih kanala Futsal Zadra.
''';

const String kPrivacyPolicyText = '''
POLITIKA PRIVATNOSTI

Zadnja izmjena: 22. srpnja 2026.

1. UVOD

Ova Politika privatnosti opisuje koje podatke prikuplja mobilna aplikacija Futsal Zadar ("Aplikacija"), kako ih koristi i koja su vaša prava.

2. PODACI KOJE PRIKUPLJAMO

• Anonimni korisnički identifikator — pri prvom pokretanju Aplikacija kreira anonimni račun (Firebase Authentication) kako bi se vaši favoriti i postavke obavijesti mogli spremiti. Ne prikupljamo vaše ime, e-mail adresu ni druge osobne podatke.
• Token uređaja za obavijesti — ako su obavijesti omogućene, koristi se Firebase Cloud Messaging token uređaja za dostavu push obavijesti.
• Favoriti i pretplate — popis klubova, igrača i utakmica koje ste označili kao favorite, povezan s vašim anonimnim identifikatorom.

3. SVRHA OBRADE

Navedene podatke koristimo isključivo za:
• spremanje vaših favorita i postavki;
• dostavu push obavijesti koje ste omogućili;
• osnovno tehničko funkcioniranje Aplikacije.

Podatke ne koristimo za oglašavanje niti ih prodajemo trećim stranama.

4. PRUŽATELJI USLUGA

Aplikacija koristi usluge Google Firebase (Authentication, Cloud Firestore, Cloud Messaging) za pohranu podataka i dostavu obavijesti. Na obradu podataka od strane Googlea primjenjuje se Googleova politika privatnosti (https://policies.google.com/privacy).

5. ČUVANJE PODATAKA

Podaci o favoritima čuvaju se dok ih ne uklonite ili dok ne izbrišete Aplikaciju i povezani anonimni račun. Lokalna predmemorija podataka pohranjuje se na vašem uređaju i briše se deinstalacijom Aplikacije.

6. VAŠA PRAVA

Imate pravo zatražiti informaciju o podacima povezanima s vašim anonimnim identifikatorom te njihovo brisanje. Obavijesti možete u svakom trenutku onemogućiti u postavkama uređaja, a favorite ukloniti unutar Aplikacije.

7. DJECA

Aplikacija ne prikuplja svjesno osobne podatke djece. Aplikacija je namijenjena općoj publici i ne zahtijeva unos osobnih podataka.

8. IZMJENE POLITIKE

Zadržavamo pravo izmjene ove Politike privatnosti. O bitnim izmjenama obavijestit ćemo vas putem Aplikacije.

9. KONTAKT

Za pitanja o privatnosti i zaštiti podataka možete nas kontaktirati putem službenih kanala Futsal Zadra.
''';
