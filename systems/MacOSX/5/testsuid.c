
int
main()
{
     int status = 0;
     setuid(1);
     if(
        seteuid(0) != -1 ||
	setuid(0) != -1)
        status = 1;
     exit(status);
}
