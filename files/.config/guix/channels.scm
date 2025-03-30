(list (channel
       (name 'nonguix)
       (url "https://gitlab.com/nonguix/nonguix")
       (introduction
        (make-channel-introduction
         "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
         (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
       (name 'guix)
       (url "https://git.savannah.gnu.org/git/guix.git")
       (introduction
        (make-channel-introduction
         "9edb3f66fd807b096b48283debdcddccfea34bad"
         (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))
      (channel
       (name 'radix)
       (url "https://codeberg.org/anemofilia/radix.git")
       (branch "main")
       (introduction
	(make-channel-introduction
	 "f9130e11e35d2c147c6764ef85542dc58dc09c4f"
	 (openpgp-fingerprint
          "F164 709E 5FC7 B32B AEC7  9F37 1F2E 76AC E3F5 31C8"))))
      (channel
       (name 'saayix)
       (branch "main")
       (url "https://codeberg.org/look/saayix")
       (introduction
	(make-channel-introduction
	 "12540f593092e9a177eb8a974a57bb4892327752"
	 (openpgp-fingerprint
          "3FFA 7335 973E 0A49 47FC  0A8C 38D5 96BE 07D3 34AB")))))
