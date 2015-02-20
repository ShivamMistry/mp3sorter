
/*
 * mp3sorter.c
 *
 * Sorts mp3 files into directories as dir/artist/album/title.mp3
 *
 *  Created on: Jan 21, 2012
 *  Author: S. Mistry (speed)
 */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <stdlib.h>


void sort(const char* file, const char* dest_dir)
{
        FILE* fp, *nf;
        fp = fopen(file, "r");
        if (fp != NULL)
        {
                //seek to beginning of id3v1 tag (128 bytes from end)
                fseek(fp, -128, SEEK_END);
                char tag[4];
                char title[31], artist[31], album[31];
                //read tag title from file
                fgets(tag, 4, fp);
                //check for id3v1
                if (strcmp(tag, "TAG") == 0)
                {
                        printf("ID3v1 detected for file %s\n", file);
                        fgets(title, 31, fp);
                        fgets(artist, 31, fp);
                        fgets(album, 31, fp);
                        //replace forward slashes with back slashes
                        //so files aren't recognised as directories
                        char * pch;
                        pch = strchr(title, '/');
                        while (pch != NULL)
                        {
                                //replace the / with a back slash
                                title[pch - title] = '\\';
                                //search from char after current slash
                                pch = strchr(pch + 1, '/');
                        }
                        //print names
                        printf("%s - %s on %s\n", title, artist, album);

                }
                else
                {
                        //TODO check id3v2
                        fclose(fp);
                        return;

                }
                char* dir = malloc(
                                strlen(dest_dir) + strlen(artist) + strlen(album)
                                                + strlen(title) + 8);
                sprintf(dir, "%s/%s", dest_dir, artist);
                //create artist directory
                mkdir(dir, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
                sprintf(dir, "%s/%s", dir, album);
                //create album directory
                mkdir(dir, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
                puts(dir);
                //append file name to path
                sprintf(dir, "%s/%s.mp3", dir, title);
                fclose(fp);
                //move file
                if (rename(file, dir) == 0)
                {
                        //successful move is successful
                        free(dir);
                        return;
                }
                else
                {
                        //if the move failed, copy and delete
                        fp = fopen(file, "r");
                        nf = fopen(dir, "w");
                        int ch;
                        while (!feof(fp))
                        {
                                //read single char from file
                                ch = fgetc(fp);
                                if (ferror(fp))
                                {
                                        puts("Error reading source file.");
                                        break;
                                }
                                if (!feof(nf))
                                {
                                        //write char to new file
                                        fputc(ch, nf);
                                }
                                if (ferror(nf))
                                {
                                        puts("Error writing destination file.");
                                        break;
                                }
                        }
                        fclose(nf);
                        fclose(fp);
                        free(dir);
                        //delete old file
                        remove(file);
                        return;
                }

        }
        fclose(fp);
}

void sort_dir(const char *path, const char* dir_path)
{
        DIR *dir;
        dir = opendir(path);
        struct dirent *curr;
        while ((curr = readdir(dir)) != NULL)
        {
                //loop through all files in directory
                if (strstr(curr->d_name, ".mp3") != NULL) //check for mp3 files
                {
                        char* full_path = malloc(strlen(path) + strlen(curr->d_name) + 2);
                        //append file name to directory
                        sprintf(full_path, "%s/%s", path, curr->d_name);
                        puts(full_path);
                        //process this file
                        sort(full_path, dir_path);
                        //free the allocated mem for the path
                        free(full_path);

                }
        }
        closedir(dir);

}

int main(int argc, char **argv)
{

        if (argc == 1)
        {
                puts("Usage: mp3sorter  (directory|file)... out-dir");
        }
        else if (argc >= 2)
        {
                char* dir;
                char buffer[1024];
                if (argc == 2)
                {
                        //if no out dir is supplied, use current working dir
                        dir = getcwd(buffer, sizeof(buffer));

                }
                else
                {
                        //use last arg as out dir
                        dir = argv[argc - 1];
                }
                puts(dir);
                int curr;
                //loop through all args except for output dir unless no out is supplied
                for (curr = 1; curr < (argc == 2 ? 2 : argc - 1); curr++)
                {
                        char* path = argv[curr];
                        struct stat s;
                        //read file attributes into stat struct
                        if (stat(path, &s) == 0)
                        {
                                if (S_ISDIR(s.st_mode))
                                {
                                        //the passed path was a directory
                                        sort_dir(path, dir);

                                }
                                else if (S_ISREG(s.st_mode))
                                {
                                        //single file passed
                                        sort(argv[1], dir);
                                }
                        }
                }
        }
        return 0;
}
