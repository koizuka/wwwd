���̃��W���[��[components]�̃r���h���@
2001-04-28 ���� koizuka@koizuka.jp

Delphi/C++Builder�̃��j���[���
[�R���|�[�l���g(C)]���j���[����[�R���|�[�l���g�̃C���X�g�[��(I)]��I��
[�V�K�p�b�P�[�W�ɒǉ�]�^�u��I��
���j�b�g�t�@�C����(U)�̉E��[�Q��(B)]�������ADelphi���j�b�g(*.pas)��
�I��ŁA���̃t�H���_�̂��ׂĂ�pas�t�@�C������x�ɑI���A�J��(O)����

�ǉ��_�C�A���O�ɖ߂�̂ŁA�p�b�P�[�W�t�@�C�������ɐV�K�̖��O��t����
���͂��̃t�H���_�̉���CB4��Delphi4�Ȃǂ̃t�H���_���@���āA������
koizuka.dpk��koizuka.bpk�Ƃ����t�@�C�����ō���Ă��܂��B

�p�b�P�[�W�̐����͓K���ɓ��͂��Ă��������B

�����OK�������Ƃ����R���p�C�����邩�ƕ�����邪�A�����ł�[������]

�p�b�P�[�W�v���W�F�N�g�̃E�B���h�E����A�I�v�V�����{�^���������āA
�f�B���N�g��/�����^�u�̃��j�b�g�o�̓f�B���N�g������obj�ȂǂƂ��A
�����悤��obj�t�H���_���쐬����
(Delphi3�ł͂���͖����̂ł��Ȃ��Ă��d���Ȃ��ł�)

���ꂩ��R���p�C������Ƃ���������B


�� ���W���[���ꗗ

AsyncHttp.pas - �񓯊��^HTTP�R���|�[�l���g
  requires: Sockets.pas

Base64.pas - BASE64�G���R�[�f�B���O�֐�


CharSetDetector.pas - ���{�ꕶ���R�[�h���ʂ�Q�i�I�ɍs���X�g���[���I�N���X



ChatFilter.pas - �����񂩂�Windows�̓��{��@��ˑ�������r���E�u��������֐�



ClickableView.pas - ���{���p��RichEdit�̂悤�Ȓ�@�\�r���[�R���|�[�l���g



crc.pas - CRC32�Z�o�֐�
�@zlib���̂��̂�pascal���������̂ł��B


DropURLListTarget - URL���X�g��Drag Drop�Ŏ󂯎��R���|�[�l���g
  requires: Drag and Drop Component Stuite 3.7 http://www.melander.dk/
�@���炩���ߏ�L�R���|�[�l���g���C���X�g�[�����Ă����Ԃł̂�
�C���X�g�[���ł��܂��B

TrayIcon.pas - �^�X�N�g���C�A�C�R���R���|�[�l���g



UrlFunc.pas - URL�֘A�����񏈗��֐�
function DecodeRFC822Date( rfc822dateString: string ): TDateTime;
procedure SplitHostPort(s: string; var host:string; var port:integer );
procedure SplitUrl(url: string; var sProtocol, sID, sPassword, sHost, sPort, sPath: string );
function ComplementURL(const relative_uri, base_uri: string): string;


Sockets.pas - �\�P�b�g�x�[�X�����R���|�[�l���g
�@�񓯊��^�\�P�b�g�R���|�[�l���g�y�шȉ��̊֐��E�葱��


SocketIrc.pas - IRC�p�R���|�[�l���g(������)
  requires: Sockets.pas


SmfPlayer.pas - SMFDRV.DLL (C)ajax ���g���� midi�Đ�������R���|�[�l���g



Kanjis.pas - ���{��̊����R�[�hJIS/SJIS�ϊ����j�b�g
�@1�����P�ʂ�JIS/SJIS���ݕϊ��֐�
�@������S�̂�JIS/SJIS���ݕϊ��֐�
�@�����񒆂̔��p�J�i��S�p�J�i�ɒu��������֐�


httpAuth.pas - AsyncHTTP�ƂƂ��Ɏg���AHTTP�F�؂��������邽�߂̃T�|�[�g�N���X
  requires: AsyncHttp.pas
  requires: MD5.pas  http://www.fichtner.net/delphi/md5.delphi.phtml
�@MD5.pas�����̃f�B���N�g���Ȃǂɔz�u���Ă���R���p�C�����Ă��������B
